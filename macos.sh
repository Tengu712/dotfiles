#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

copy_file() {
	local src="$DOTFILES_DIR/src/$1"
	local dst="$HOME/$1"
	mkdir -p "$(dirname "$dst")"
	cp "$src" "$dst"
	echo "copied $src -> $dst"
}

copy_file .zsh_prompt
copy_file .zsh_aliases
copy_file .vimrc
