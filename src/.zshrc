# Prompt
function set_prompt() {
	PROMPT='%(?.%F{cyan}.%F{red})%n@%m %c %# %f'
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_prompt

# Path
export PATH="$HOME/.executables:$PATH"
eval "$(mise activate zsh)"

# Utils
function rbg() {
	"$@" > /dev/null 2>&1 &
}
alias tc='tee >(pbcopy)'

# Search
alias af='search af'
alias ag='search ag'

# Vim
alias vf='vim -c VF'
alias vg='vim -c VG'

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
