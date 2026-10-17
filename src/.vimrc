" General
set t_Co=256
set clipboard+=unnamed
set mouse=
set cursorline
set cursorlineopt=number
set re=0
set shiftwidth=4
set tabstop=4
set softtabstop=4
set notermguicolors
let mapleader = "\<Space>"

" fern
let g:fern#renderer = "nerdfont"
let g:fern#default_hidden = 1
let g:fern#default_exclude = '^\%(\.git\|\.cache\|.*\.swp\|target\)$'
autocmd FileType fern setlocal nowrap

" Show special characters
set list
set listchars=tab:>-,eol:$,nbsp:_

" Syntax highlight
syntax on
filetype on

" Color Changes
"" Normal
highlight Normal         cterm=NONE ctermfg=252
"" listchars
highlight NonText        cterm=NONE ctermfg=238
highlight SpecialKey     cterm=NONE ctermfg=238
"" comments
highlight Comment        cterm=NONE ctermfg=244
highlight SpecialComment cterm=NONE ctermfg=244
highlight VimLineComment cterm=NONE ctermfg=244
"" others
highlight IncSearch      cterm=NONE ctermfg=0   ctermbg=255
highlight SignColumn     cterm=NONE             ctermbg=NONE

" Bindings
inoremap <silent> jj <ESC>
nnoremap f /

" Settings for each languages
autocmd FileType rust  setlocal expandtab nolist
autocmd FileType swift setlocal expandtab nolist
autocmd FileType go    setlocal nolist

" Utils
command! LN echo line('.')
command! HG echo synIDattr(synID(line("."), col("."), 1), "name")
command! E  execute 'Fern ' . fnameescape(trim(system('git -C ' . shellescape(expand('%:p:h')) . ' rev-parse --show-toplevel'))) . ' -drawer -width=' . &columns / 4

"" list 0-255 colors
function! ShowColors()
	new
	for i in range(0, 15)
		let s = ''
		for j in range(0, 15)
			let n = i * 16 + j
			let s .= printf('%3d ', n)
		endfor
		call append(line('$'), s)
	endfor
	1d
	for i in range(0, 255)
		execute 'highlight Color' . i . ' ctermfg=' . i
		execute 'syntax match Color' . i . ' /\<' . i . '\>/'
	endfor
	setlocal readonly nomodifiable buftype=nofile bufhidden=wipe noswapfile
endfunction
command! Colors call ShowColors()

" Plugins
runtime line-jumper/script.vim
runtime search/script.vim
runtime surround/script.vim
runtime swank-client/script.vim
