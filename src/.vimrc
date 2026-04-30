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

" Settings for each languages
autocmd FileType rust setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
