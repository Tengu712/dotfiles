function! s:SearchExitCallback(tmpfile, bufnr) abort
	let l:result = readfile(a:tmpfile)
	call delete(a:tmpfile)

	if len(l:result) == 0
		if a:bufnr != -1
			execute 'buffer' a:bufnr
		endif
		return
	endif

	let l:parts = split(l:result[0], ':')
	let l:filepath = l:parts[0]
	let l:linenum = len(l:parts) > 1 ? l:parts[1] : '1'

	let l:winnr = bufwinnr(bufnr(l:filepath))
	if winnr != -1
		execute winnr . 'wincmd w'
	else
		execute 'edit +' . l:linenum . ' ' . fnameescape(l:filepath)
	endif
endfunction

function! s:SearchWith(arg) abort
	let l:tmpfile = tempname()
	let l:bufnr = empty(bufname('%')) ? -1 : bufnr('%')
	call term_start(['search', a:arg, l:tmpfile], {
		\ 'exit_cb': {_job, _status -> s:SearchExitCallback(l:tmpfile, l:bufnr)},
		\ 'term_finish': 'close',
		\ 'curwin': 1,
	\ })
endfunction

command! VF call s:SearchWith('af')
command! VG call s:SearchWith('ag')
