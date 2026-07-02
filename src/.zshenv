# Utils
function rbg() {
	"$@" > /dev/null 2>&1 &
}
function tc() {
	tee >(pbcopy)
}
function af() {
	fd --hidden --type f \
		--exclude .git \
		--exclude build \
		--exclude target \
		--exclude .opam \
		--exclude _opam \
		--exclude _build \
		--exclude node_modules \
	| fzf --preview "bat {}"
}
function ag() {
	rg --hidden --line-number --no-heading --color=never --no-messages \
		--glob '!.git/**' \
		--glob '!build/**' \
		--glob '!target/**' \
		--glob '!.opam/**' \
		--glob '!_opam/**' \
		--glob '!_build/**' \
		--glob '!node_modules/**' \
		"" \
	| fzf \
		--delimiter : \
		--with-nth 3.. \
		--preview '
			file={1}
			line={2}
			start=$((line > 200 ? line - 200 : 1))
			end=$((line + 200))
			bat --style=numbers --color=always \
				--highlight-line "$line" \
				--line-range "$start:$end" \
				-- "$file"
		' \
		--preview-window 'right,border,+{2}/2' \
		--preview-label ' ' \
		--bind 'focus:transform-preview-label:echo " {1} "' \
	| cut -d: -f1,2
}

# Git
alias gs='git status'
alias gl='git log'
alias ga='git add -A'
alias gm='git commit -m'
alias gpush='git push origin HEAD'
alias groot='git commit --allow-empty -m "root commit"'
alias gsuir='git submodule update --init --recursive'

# Lazygit
alias lg='lazygit'

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
alias dcb='docker compose build'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcx='docker compose exec'

# Nix
ndc() { nix develop --command "$@"; }
