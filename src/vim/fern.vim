let g:fern#renderer = "nerdfont"
let g:fern#default_hidden = 1
let g:fern#default_exclude = '^\%(\.git\|\.cache\|.*\.swp\|target\|\.DS_Store\)$'

autocmd FileType fern setlocal nowrap nonumber
autocmd FileType fern nmap <buffer><nowait> S <Plug>(fern-action-open:split)
autocmd FileType fern nmap <buffer><nowait> V <Plug>(fern-action-open:vsplit)

function! OpenFern(width)
	let root = trim(system('git -C ' . shellescape(getcwd()) . ' rev-parse --show-toplevel'))
	if v:shell_error
		let root = getcwd()
	endif
	unlet! t:fern_drawer_auto_resize_width
	execute 'Fern ' . fnameescape(root) . ' -drawer -width=' . (empty(a:width) ? 30 : a:width)
endfunction

command! -nargs=? E call OpenFern(<q-args>)
