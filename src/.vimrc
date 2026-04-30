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

"" Aliases
let $BASH_ENV = "~/.zsh_aliases"

" Bindings
inoremap <silent> jj <ESC>

" Commands
function! FzfEdit(cmd)
	let tmp = tempname()
	silent execute '!' . a:cmd . ' > ' . shellescape(tmp)
	redraw!
	let lines = readfile(tmp)
	call delete(tmp)
	if !empty(lines)
		execute 'edit ' . fnameescape(lines[0])
	endif
endfunction
command! VF call FzfEdit('af')
command! VG call FzfEdit('ag')

" Settings for each languages
autocmd FileType rust setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
