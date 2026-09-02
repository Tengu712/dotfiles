# Prompt
function set_prompt() {
	PROMPT='%(?.%F{cyan}.%F{red})%n@%m %c %# %f'
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_prompt

# Path
export PATH="$HOME/.executables:$PATH"

# Utils
function rbg() {
	"$@" > /dev/null 2>&1 &
}
alias tc='tee >(pbcopy)'

# Search
alias af='search af'
alias ag='search ag'

# Git
alias gs='git status'
alias gl='git log'
alias ga='git add -A'
alias gm='git commit -m'
alias gpush='git push origin HEAD'
alias groot='git commit --allow-empty -m "root commit"'
alias gsuir='git submodule update --init --recursive'

# Vim
alias vf='af | vim -c OpenFromPipe - --not-a-term'
alias vg='ag | vim -c OpenFromPipe - --not-a-term'

# Lazygit
alias lg='lazygit'

# Docker
alias dprune='docker system prune'
alias dcb='docker compose build'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcx='docker compose exec'

# Nix
alias ndc='nix develop --command'
