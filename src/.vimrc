" Settings
"" General
set clipboard+=unnamed
set cursorline
set re=0

"" Syntax highlight
syntax on
filetype on

"" Show special characters
set list
set listchars=tab:>-,eol:$,nbsp:_
highlight SpecialKey ctermfg=darkgray guifg=#555555
highlight NonText ctermfg=darkgray guifg=#555555

" Row Jumper
let s:jump_chars = []
for s:c1 in range(97, 122)
	for s:c2 in range(97, 122)
		call add(s:jump_chars, nr2char(s:c1) . nr2char(s:c2))
	endfor
endfor
function! s:EasyJump()
	let winid = win_getid()

	let key_line_map = {}
	let popup_ids = []
	let visible_idx = 0
	let i = line('w0')

	while i <= line('w$')
		let c = get(s:jump_chars, visible_idx, '')
		if c == ''
			break
		endif

		let spos = screenpos(winid, i, 1)
		if spos.row > 0
			let key_line_map[c] = i
			call add(popup_ids, popup_create(c, #{line: spos.row, col: spos.col, highlight: 'IncSearch'}))
			let visible_idx += 1
		endif

		let fold_end = foldclosedend(i)
		if fold_end != -1
			let i = fold_end + 1
		else
			let i += 1
		endif
	endwhile

	redraw
	let input = nr2char(getchar()) . nr2char(getchar())

	call map(popup_ids, 'popup_close(v:val)')

	if has_key(key_line_map, input)
		exe key_line_map[input]
	endif
endfunction
nnoremap r :call <SID>EasyJump()<CR>

" Filer
let g:netrw_liststyle = 3
let g:netrw_fastbrowse = 2
function! ToggleNetrwMinimize()
		let l:netrw = filter(getbufinfo(), 'getbufvar(v:val.bufnr, "&filetype") ==# "netrw"')
		if empty(l:netrw)
				execute 'topleft ' . ((&columns * 15) / 100) . 'vsplit'
				Explore
		elseif empty(l:netrw[0].windows)
				execute 'topleft ' . ((&columns * 15) / 100) . 'vsplit'
				execute 'buffer' l:netrw[0].bufnr
				for l:key in keys(b:)
						if l:key =~# '^saved_netrw_'
								let l:w_key = substitute(l:key, '^saved_', '', '')
								call setwinvar(0, l:w_key, getbufvar('%', l:key))
						endif
				endfor
		else
				call win_gotoid(l:netrw[0].windows[0])
				for l:key in keys(w:)
						if l:key =~# '^netrw_'
								call setbufvar('%', 'saved_' . l:key, getwinvar(0, l:key))
						endif
				endfor
				hide
		endif
endfunction
command! T call ToggleNetrwMinimize()

" Bindings
inoremap <silent> jj <ESC>
inoremap ( ()<Left>
inoremap { {}<Left>
inoremap [ []<Left>
inoremap " ""<Left>
inoremap ' ''<Left>
nnoremap f /

" Commands
function! AfEdit()
	let tmp = tempname()
	silent execute '!af > ' . shellescape(tmp)
	redraw!
	let lines = readfile(tmp)
	call delete(tmp)
	if !empty(lines)
		execute 'edit ' . fnameescape(lines[0])
	endif
endfunction
command! VF call AfEdit()
function! AgEdit()
	let tmp = tempname()
	silent execute '!ag > ' . shellescape(tmp)
	redraw!
	let lines = readfile(tmp)
	call delete(tmp)
	if !empty(lines)
		let parts = split(lines[0], ':')
		let filename = parts[0]
		let lnum = parts[1]
		execute 'edit +' . lnum . ' ' . fnameescape(filename)
	endif
endfunction
command! VG call AgEdit()
command! LN echo line('.')

" Settings for each languages
autocmd FileType rust setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4 nolist
autocmd FileType swift setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4 nolist

" =========================================================================== "
"     Lisp                                                                    "
" =========================================================================== "

let g:swank_channel = v:null

augroup LispSwank
	autocmd!
	autocmd FileType lisp call s:LispSwankInit()
augroup END

function! s:LispSwankInit()
	command! -buffer SWANK call s:SwankOpenClose()
	nnoremap <buffer> <silent> <leader>ef :call <SID>SwankEvalBuffer()<CR>
	nnoremap <buffer> <silent> <leader>ee :call <SID>SwankEvalForm()<CR>
endfunction

"" Buffer

function! s:SwankOpenClose()
	" NOTE: if not connected to swank server yet, try to connect
	if g:swank_channel is v:null || ch_status(g:swank_channel) !=# 'open'
		if s:SwankConnect() is v:false
			return
		endif
	endif

	let l:bufname = '%SWANK-LOG%'
	let l:winnr = bufwinnr(l:bufname)

	" if swank log buffer is opened, close it
	if l:winnr != -1
		execute l:winnr . 'wincmd w'
		close
	" otherwise
	else
		" split window
		let l:prevwin = winnr()
		let l:width = float2nr(&columns * 0.25)
		execute 'botright ' . l:width . 'vnew'

		" if the buffer exists, reuse it
		if bufnr(l:bufname) != -1
			silent execute 'buffer ' . bufnr(l:bufname)
		" otherwise, create it
		else
			silent execute 'file ' . escape(l:bufname, '%#')
			setlocal buftype=nofile bufhidden=hide noswapfile
		endif

		" return to previous window
		execute l:prevwin . 'wincmd w'
	endif
endfunction

function! s:SwankConnect() abort
	call s:SwankStartProxy()

	let l:tries = 0
	while l:tries < 30 && job_status(g:swank_proxy_job) ==# 'run'
		let g:swank_channel = ch_open('127.0.0.1:4006', {
			\ 'mode': 'raw',
			\ 'callback': function('s:SwankCallback'),
			\ 'waittime': 1000,
		\ })
		if ch_status(g:swank_channel) ==# 'open'
			echo 'SWANK: connected'
			return v:true
		endif
		let l:tries += 1
		sleep 500m
	endwhile

	echoerr 'SWANK: failed to connect'
	let g:swank_channel = v:null
	return v:false
endfunction

function! s:SwankCallback(channel, msg)
	call s:SwankLogAppend(a:msg)
endfunction

function! s:SwankLogAppend(msg)
	let l:bufnr = bufnr('%SWANK-LOG%')
	if l:bufnr != -1
		call appendbufline(l:bufnr, '$', split(a:msg, "\n"))
	endif
endfunction

"" Proxy

function! s:SwankStartProxy()
	if exists('g:swank_proxy_job') && job_status(g:swank_proxy_job) ==# 'run'
		return
	endif

	if !executable('ros')
		echoerr 'SWANK: ros command not found'
		return
	endif

	let l:swank_proxy_lisp = join([
		\ '(sb-ext:disable-debugger)',
		\ '(unless (find-package :usocket) (require :usocket) (unless (find-package :usocket) (uiop:quit 2)))',
		\ '(defvar *swank-socket* (handler-case (usocket:socket-connect "127.0.0.1" 4005) (error () (uiop:quit 3))))',
		\ '(defvar *swank-stream* (usocket:socket-stream *swank-socket*))',
		\ '(defvar *listener* (usocket:socket-listen "127.0.0.1" 4006 :reuseaddress t))',
		\ '(defvar *id* 0)',
		\ '(defun read-frame (stream)',
		\ '  (let ((header (make-string 6)))',
		\ '    (unless (zerop (read-sequence header stream))',
		\ '      (let* ((len (parse-integer header :radix 16))',
		\ '             (body (make-string len)))',
		\ '        (read-sequence body stream)',
		\ '        body))))',
		\ '(defun send-frame (stream body)',
		\ '  (format stream "~6,''0x~a" (length body) body)',
		\ '  (force-output stream))',
		\ '(defun split-forms (code)',
		\ '  (let ((forms ''()))',
		\ '    (with-input-from-string (in code)',
		\ '      (loop',
		\ '        (let ((form (read in nil :eof)))',
		\ '          (when (eq form :eof) (return))',
		\ '          (push (prin1-to-string form) forms))))',
		\ '    (nreverse forms)))',
		\ '(loop',
		\ '  (let* ((client (usocket:socket-accept *listener*))',
		\ '         (client-stream (usocket:socket-stream client)))',
		\ '    (loop',
		\ '      (let ((code (read-frame client-stream)))',
		\ '        (when (null code) (return))',
		\ '        (dolist (form (split-forms code))',
		\ '         (let ((my-id (incf *id*)))',
		\ '           (send-frame *swank-stream* (format nil "(:emacs-rex (swank:eval-and-grab-output ~s) \"common-lisp-user\" t ~d)" form my-id))',
		\ '           (loop',
		\ '             (let* ((reply      (read-frame *swank-stream*))',
		\ '                    (event      (read-from-string reply))',
		\ '                    (event-type (car event))',
		\ '                    (event-msg  (second event))',
		\ '                    (event-id   (third event)))',
		\ '               (cond',
		\ '                 ((and (eq event-type :return) (eql event-id my-id))',
		\ '                  (let ((result (if (eq (car event-msg) :ok)',
		\ '                                     (second (second event-msg))',
		\ '                                     (format nil "abort: ~a" (second event-msg)))))',
		\ '                    (format client-stream "~a~%" result)',
		\ '                    (force-output client-stream))',
		\ '                  (return))',
		\ '                 ((eq event-type :debug)',
		\ '                  (let* ((condition (fourth event))',
		\ '                         (restarts  (fifth event))',
		\ '                         (desc  (first condition))',
		\ '                         (type  (string-trim (list #\Space) (second condition)))',
		\ '                         (names (mapcar #''first restarts)))',
		\ '                    (send-frame *swank-stream* (format nil "(:emacs-rex (swank:throw-to-toplevel) \"common-lisp-user\" ~d ~d)" event-msg (incf *id*)))',
		\ '                    (format client-stream "~a~%" (format nil "; ~a~%; ~a~%; restarts: ~{~a~^, ~}" desc type names))',
		\ '                    (force-output client-stream)))',
		\ '                 (t nil))))))))))',
		\ ], '')

	let g:swank_proxy_job = job_start(['ros', '--script', '-e', l:swank_proxy_lisp], { 'exit_cb': function('s:SwankProxyExit') })
endfunction

function! s:SwankProxyExit(job, status)
	if a:status == 2
		echoerr 'SWANK: fatal: usocket not installed'
	elseif a:status == 3
		echoerr 'SWANK: fatal: swank server not running on 4005'
	elseif a:status != 0
		echoerr 'SWANK: error: proxy exited with status ' . a:status
	endif
endfunction

"" Evaluation

function! s:SwankEvalBuffer()
	call s:SwankEvalString(join(getline(1, '$'), "\n"))
endfunction

function! s:SwankEvalForm()
	let l:save = winsaveview()
	let l:reg = [getreg('z'), getregtype('z')]
	silent! normal! "zya(
	let l:text = getreg('z')
	call setreg('z', l:reg[0], l:reg[1])
	call winrestview(l:save)
	call s:SwankEvalString(l:text)
endfunction

function! s:SwankEvalString(code)
	if g:swank_channel is v:null || ch_status(g:swank_channel) !=# 'open'
		echoerr 'SWANK not connected'
		return
	endif

	let l:header = printf('%06x', len(a:code))
	call ch_sendraw(g:swank_channel, l:header . a:code)
endfunction
