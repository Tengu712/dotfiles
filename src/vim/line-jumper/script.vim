let s:jump_chars = []

for s:c1 in range(97, 99)
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
