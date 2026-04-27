#!/bin/bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

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

copy_file src/lazygit-config.yml  "$(lazygit --print-config-dir)/config.yml"
