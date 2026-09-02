" General
set t_Co=256
set clipboard+=unnamed
set cursorline
set cursorlineopt=number
set re=0
set shiftwidth=4
set tabstop=4
set softtabstop=4
set notermguicolors
let mapleader = "\<Space>"

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

" Bindings
inoremap <silent> jj <ESC>
nnoremap f /
inoremap ( ()<Left>
inoremap { {}<Left>
inoremap [ []<Left>
inoremap < <><Left>
inoremap " ""<Left>
inoremap ' ''<Left>
inoremap ` ``<Left>
function! s:smart_bs()
	let l:pair = strpart(getline('.'), col('.') - 2, 2)
	if col('.') > 1 && index(['()', '{}', '[]', '<>', '""', "''", '``'], l:pair) >= 0
		return "\<Del>"
	else
		return "\<BS>"
	endif
endfunction
inoremap <expr> <BS> <SID>smart_bs()

" Settings for each languages
autocmd FileType rust  setlocal expandtab nolist
autocmd FileType swift setlocal expandtab nolist
autocmd FileType go    setlocal nolist

" Utils
command! LN echo line('.')
command! HG echo synIDattr(synID(line("."), col("."), 1), "name")
command! E  execute 'edit .'
command! EE execute 'edit %:h'
command! ER execute 'edit #'

"" open with af
function! AfEdit()
	" TODO: remove temp file
	let tmp = tempname()
	silent execute '!search af > ' . shellescape(tmp)
	redraw!
	let lines = readfile(tmp)
	call delete(tmp)
	if !empty(lines)
		execute 'edit ' . fnameescape(lines[0])
	endif
endfunction
command! VF call AfEdit()

"" open with ag
function! AgEdit()
	" TODO: remove temp file
	let tmp = tempname()
	silent execute '!search ag > ' . shellescape(tmp)
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

"" start vim with af
function! s:start_with_af()
	call AfEdit()
endfunction
command! StartWithAF call <SID>start_with_af()

"" start vim with ag
function! s:start_with_ag()
	call AgEdit()
endfunction
command! StartWithAG call <SID>start_with_ag()

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
runtime swank-client/script.vim

" ============================================================================ "
"     Line Jumper                                                              "
" ============================================================================ "

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
