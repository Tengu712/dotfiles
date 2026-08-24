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

" Buffer

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

" Proxy

function! s:SwankStartProxy()
	if exists('g:swank_proxy_job') && job_status(g:swank_proxy_job) ==# 'run'
		return
	endif

	if !executable('ros')
		echoerr 'SWANK: ros command not found'
		return
	endif

	let l:path = globpath(&runtimepath, 'swank-client/proxy.lisp')
	if empty(l:path)
		echoerr 'SWANK: fatal: proxy.lisp not found'
	endif

	let g:swank_proxy_job = job_start(['ros', '--script', split(l:path, "\n")[0]], { 'exit_cb': function('s:SwankProxyExit') })
endfunction

function! s:SwankProxyExit(job, status)
	if a:status == 2
		echoerr 'SWANK: fatal: usocket not installed'
	elseif a:status == 3
		echoerr 'SWANK: fatal: eclector not installed'
	elseif a:status == 4
		echoerr 'SWANK: fatal: swank server not running on 4005'
	elseif a:status != 0
		echoerr 'SWANK: error: proxy exited with status ' . a:status
	endif
endfunction

" Evaluation

function! s:SwankEvalBuffer()
	call s:SwankSendCode('C', join(getline(1, '$'), "\n"))
endfunction

function! s:SwankEvalForm()
	let l:save = winsaveview()
	let l:reg = [getreg('z'), getregtype('z')]
	silent! normal! "zya(
	let l:text = getreg('z')
	call setreg('z', l:reg[0], l:reg[1])
	call winrestview(l:save)
	call s:SwankSendCode('E', l:text)
endfunction

function! s:SwankSendCode(tag, code)
	if g:swank_channel is v:null || ch_status(g:swank_channel) !=# 'open'
		echoerr 'SWANK not connected'
		return
	endif

	let l:payload = a:tag . a:code
	let l:header = printf('%06x', len(l:payload))
	call ch_sendraw(g:swank_channel, l:header . l:payload)
endfunction
