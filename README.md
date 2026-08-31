# dotfiles

Use zsh on macOS, cmd on Windows and install following commands:

- lazygit
- python
- vim

Run `apply.py` with Python:

```
python apply.py
```

On macOS, add the following code to `.zshrc`:

```sh
if [ -f ~/.zsh_prompt ]; then
	source ~/.zsh_prompt
fi
```
