#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

copy_directory() {
	if [ -d "$2" ]; then
		rm -rf "$2"
	fi
	cp -r "$1" "$2"
	echo "copied $1 -> $2"
}

copy_file() {
	mkdir -p "$(dirname "$2")"
	cp "$1" "$2"
	echo "copied $1 -> $2"
}

copy_file_util() {
	local src="$DOTFILES_DIR/src/$1"
	local dst="$HOME/$1"
	copy_file "$src" "$dst"
}

copy_file_util .zsh_prompt
copy_file_util .zshenv
copy_file_util .vimrc

vim -es -c 'redir! > /tmp/vim-config-path.txt' -c 'echo split(&runtimepath, ",")[0]' -c 'redir END' -c 'quit!' < /dev/null
copy_directory "$DOTFILES_DIR/src/vim/swank-client" "$(cat /tmp/vim-config-path.txt | xargs)/swank-client"
rm /tmp/vim-config-path.txt

copy_file "$DOTFILES_DIR/src/lazygit-config.yml" "$(lazygit --print-config-dir)/config.yml"
