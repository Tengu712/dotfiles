# Utils
function tc() {
	tee >(pbcopy)
}
function af() {
	fzf --preview "cat {}"
}
function ag() {
	rg --line-number --no-heading "" \
	| fzf \
		--delimiter : \
		--with-nth 3.. \
		--preview 'awk -v n={2} '"'"'NR==n{print "\033[7m" $0 "\033[m"; next} {print}'"'"' {1}' \
		--preview-window 'right,+{2}-10' \
	| cut -d: -f1,2
}

# Git
alias gs='git status'
alias gl='git log'
alias ga='git add -A'
alias gm='git commit -m'
alias gpush='git push origin HEAD'
alias groot='git commit --allow-empty -m "root commit"'

# Vim
vf() {
	local result
	result=$(af)
	[ -z "$result" ] && return

	print -sr -- vim "$result"
	vim "$result"
}
vg() {
	local result
	result=$(ag)
	[ -z "$result" ] && return

	local file
	local line
	file=$(echo "$result" | cut -d: -f1)
	line=$(echo "$result" | cut -d: -f2)

	print -sr -- vim +"$line" "$file"
	vim +"$line" "$file"
}

# Docker
alias dprune='docker system prune'
alias dcx='docker compose exec'
