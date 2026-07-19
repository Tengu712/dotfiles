" Settings
"" General
set clipboard+=unnamed
set cursorline

"" Syntax highlight
syntax on
filetype on

"" Show special characters
set list
set listchars=tab:>-,eol:$,nbsp:_
highlight SpecialKey ctermfg=darkgray guifg=#555555
highlight NonText ctermfg=darkgray guifg=#555555

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
