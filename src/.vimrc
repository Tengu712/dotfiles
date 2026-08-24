" ============================================================================ "
"     Settings                                                                 "
" ============================================================================ "

" General
set clipboard+=unnamed
set cursorline
set re=0
set tabstop=4
set shiftwidth=4
let mapleader = "\<Space>"

" Syntax highlight
syntax on
filetype on

" Show special characters
set list
set listchars=tab:>-,eol:$,nbsp:_
highlight SpecialKey ctermfg=darkgray guifg=#555555
highlight NonText ctermfg=darkgray guifg=#555555

" Color Changes
highlight Comment ctermfg=gray guifg=#808080
highlight SpecialComment ctermfg=gray guifg=#808080
highlight vimLineComment ctermfg=gray guifg=#808080

" Bindings
inoremap <silent> jj <ESC>
inoremap ( ()<Left>
inoremap { {}<Left>
inoremap [ []<Left>
inoremap < <><Left>
inoremap " ""<Left>
inoremap ' ''<Left>
inoremap ` ``<Left>
nnoremap f /
inoremap <expr> <BS> <SID>smart_bs()
function! s:smart_bs()
	let l:pair = strpart(getline('.'), col('.') - 2, 2)
	if col('.') > 1 && index(['()', '{}', '[]', '<>', '""', "''", '``'], l:pair) >= 0
		return "\<Del>"
	else
		return "\<BS>"
	endif
endfunction

" Settings for each languages
autocmd FileType rust setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4 nolist
autocmd FileType swift setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4 nolist

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

" ============================================================================ "
"     Filer                                                                    "
" ============================================================================ "

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

" ============================================================================ "
"     Commands                                                                 "
" ============================================================================ "

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

command! VF call AfEdit()
command! VG call AgEdit()
command! LN echo line('.')

" ============================================================================ "
"     Plugins                                                                  "
" ============================================================================ "

runtime swank-client/script.vim
