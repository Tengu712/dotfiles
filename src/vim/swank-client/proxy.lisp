(sb-ext:disable-debugger)

(unless (find-package :usocket)
        (require :usocket)
        (unless (find-package :usocket) (uiop:quit 2)))
(unless (find-package :eclector.reader)
        (ql:quickload :eclector)
        (unless (find-package :eclector.reader) (uiop:quit 3)))

;;; S-expression parser

(defclass safe-sexp-reader () ())

;; Overriding method to ignore package finding `pkg:sym`
(defmethod eclector.reader:interpret-symbol ((c safe-sexp-reader) s pkg name internp)
  (declare (ignore s internp))
  (cond
    ((and (eq pkg :current) (string= name "NIL")) nil)
    ((and (eq pkg :current) (string= name "T")) t)
    ((eq pkg :current) (make-symbol name))
    ((eq pkg :keyword) (intern name "KEYWORD"))
    ((stringp pkg) (make-symbol (format nil "~a:~a" pkg name)))
    (t (make-symbol name))))

;; Overriding method to ignore read-time evaluation `#.`
(defmethod eclector.reader:evaluate-expression ((c safe-sexp-reader) expr)
  expr)

;; Overriding method to ignore constructor `#S`
(defmethod eclector.reader:make-structure-instance ((c safe-sexp-reader) name initargs)
  (list* :struct name initargs))

(defvar *safe-sexp-reader*  (make-instance 'safe-sexp-reader))

(defun safe-read (s)
  (let ((eclector.base:*client* *safe-sexp-reader*))
    (eclector.reader:read-from-string s)))

;;; I/O

(defvar *swank-stream*
  (handler-case
    (usocket:socket-stream
      (usocket:socket-connect "127.0.0.1" 4005 :element-type '(unsigned-byte 8)))
    (error () (uiop:quit 4))))
(defvar *listener*
  (usocket:socket-listen "127.0.0.1" 4006 :reuseaddress t :element-type '(unsigned-byte 8)))
(defvar *id* 0)

(defun read-exactly (stream n)
  (let* ((buf (make-array n :element-type '(unsigned-byte 8)))
         (pos 0))
    (loop while (< pos n)
          do (let ((got (read-sequence buf stream :start pos)))
               (when (= got pos) (return-from read-exactly nil))
               (setf pos got)))
    (sb-ext:octets-to-string buf :external-format :utf-8)))

(defun read-frame (stream)
  (let ((header (read-exactly stream 6)))
    (when header
      (read-exactly stream (parse-integer header :radix 16)))))

(defun send-frame (stream body)
  (let* ((octets (sb-ext:string-to-octets body                                  :external-format :utf-8))
         (header (sb-ext:string-to-octets (format nil "~6,'0x" (length octets)) :external-format :ascii)))
    (write-sequence header stream)
    (write-sequence octets stream)
    (force-output stream)))

(defun send-message (stream msg)
  (write-sequence (sb-ext:string-to-octets (format nil "~a~%" msg) :external-format :utf-8) stream)
  (force-output stream))

(defun send-to-swank (tag code id)
  (send-frame *swank-stream*
    (ecase tag
      (#\C (format nil "(:emacs-rex (swank:compile-string-for-emacs ~s \"buffer\" '((:position 1)) nil nil) \"common-lisp-user\" t ~d)" code id))
      (#\E (format nil "(:emacs-rex (swank:eval-and-grab-output ~s) \"common-lisp-user\" t ~d)" code id)))))

(defun abort-swank (msg id)
  (send-frame *swank-stream*
    (format nil "(:emacs-rex (swank:throw-to-toplevel) \"common-lisp-user\" ~d ~d)" msg id)))

;;; Handlers

(defun symbol-name= (x name)
  (and x (symbolp x) (string= (symbol-name x) name)))

(defun handle-compile-return (client-stream event-msg)
  (if (symbol-name= (car event-msg) "OK")
    (let* ((compresult (second event-msg))
           (notes      (second compresult))
           (successp   (third compresult)))
      (if successp
        (send-message client-stream (format nil "COMPILE SUCCEEDED (~d notes)" (length notes)))
        (send-message client-stream (format nil "COMPILE FAILED: ~{~a~^; ~}" notes))))
    (send-message client-stream (format nil "ABORT: ~a" (second event-msg)))))

(defun handle-eval-return (client-stream event-msg)
  (if (symbol-name= (car event-msg) "OK")
    (let* ((result (second event-msg))
           (output (first result))
           (value  (second result)))
      (send-message client-stream (format nil "~a~a" output value)))
    (send-message client-stream (format nil "ABORT: ~a" (second event-msg)))))

(defun handle-return-event (client-stream tag event-msg)
  (ecase tag
    (#\C (handle-compile-return client-stream event-msg))
    (#\E (handle-eval-return client-stream event-msg))))

(defun handle-debug-event (client-stream event event-msg next-id)
  (let* ((condition (fourth event))
         (restarts  (fifth event))
         (desc      (first condition))
         (type      (string-trim (list #\Space) (second condition)))
         (names     (mapcar #'first restarts)))
    (abort-swank event-msg next-id)
    (send-message client-stream (format nil "; ~a~%; ~a~%; restarts: ~{~a~^, ~}" desc type names))))

;;; Main loop

(loop
  (let ((client-stream (usocket:socket-stream (usocket:socket-accept *listener*))))
    (loop
      (let ((raw (read-frame client-stream)))
        (when (null raw) (return))
        (let ((tag  (char raw 0))
              (code (subseq raw 1))
              (my-id (incf *id*)))
          (send-to-swank tag code my-id)
          (loop
            (let* ((reply      (read-frame *swank-stream*))
                   (event      (safe-read reply))
                   (event-type (car event))
                   (event-msg  (second event))
                   (event-id   (third event)))
              (cond
                ((and (symbol-name= event-type "RETURN") (eql event-id my-id))
                   (handle-return-event client-stream tag event-msg)
                   (return))
                ((symbol-name= event-type "DEBUG")
                   (handle-debug-event client-stream event event-msg (incf *id*)))
                (t nil)))))))))
