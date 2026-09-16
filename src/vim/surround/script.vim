" automatic pair insertion
inoremap ( ()<Left>
inoremap { {}<Left>
inoremap [ []<Left>
inoremap < <><Left>
inoremap ' ''<Left>
inoremap " ""<Left>
inoremap ` ``<Left>

" selected surrounding
xnoremap ( c()<Esc>P
xnoremap { c{}<Esc>P
xnoremap [ c[]<Esc>P
xnoremap < c<><Esc>P
xnoremap ' c''<Esc>P
xnoremap " c""<Esc>P
xnoremap ` c``<Esc>P

" pair deletion
function! s:DeletePair(c) abort
	if getline('.')[col('.') - 1] !=# a:c
		return
	endif
	execute 'silent! normal! yi' . a:c . '"_di' . a:c
	execute "silent! normal! i\<BS>\<Del>\<Esc>p"
endfunction
nnoremap <silent> d( :call <SID>DeletePair('(')<CR>
nnoremap <silent> d) :call <SID>DeletePair(')')<CR>
nnoremap <silent> d{ :call <SID>DeletePair('{')<CR>
nnoremap <silent> d} :call <SID>DeletePair('}')<CR>
nnoremap <silent> d[ :call <SID>DeletePair('[')<CR>
nnoremap <silent> d] :call <SID>DeletePair(']')<CR>
nnoremap <silent> d< :call <SID>DeletePair('<')<CR>
nnoremap <silent> d> :call <SID>DeletePair('>')<CR>
nnoremap <silent> d' :call <SID>DeletePair("'")<CR>
nnoremap <silent> d" :call <SID>DeletePair('"')<CR>
nnoremap <silent> d` :call <SID>DeletePair('`')<CR>

" latter deletion
function! s:DeleteLatter() abort
	let l:pair = strpart(getline('.'), col('.') - 2, 2)
	if col('.') > 1 && index(['()', '{}', '[]', '<>', '""', "''", '``'], l:pair) >= 0
		return "\<Del>"
	else
		return "\<BS>"
	endif
endfunction
inoremap <expr> <BS> <SID>DeleteLatter()
