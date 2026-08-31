import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

SYSTEM       = platform.system()
DOTFILES_DIR = Path(__file__).resolve().parent
HOME         = Path.home()

if SYSTEM == 'Linux':
	print('Linux is unsupported')
	sys.exit(1)

# =========================================================================== #
#     utils                                                                   #
# =========================================================================== #

def copy_directory(src, dst):
	if dst.exists():
		shutil.rmtree(dst)
	shutil.copytree(src, dst)
	print(f'copied {src} -> {dst}')

def copy_file(src, dst):
	dst.parent.mkdir(parents=True, exist_ok=True)
	shutil.copy2(src, dst)
	print(f'copied {src} -> {dst}')

def copy_file_to_home(path):
	copy_file(DOTFILES_DIR / 'src' / path, HOME / path)

# =========================================================================== #
#     terminal                                                                #
# =========================================================================== #

def apply_terminal_windows():
	if SYSTEM != 'Windows':
		return

	local_appdata = os.environ['LOCALAPPDATA']
	if local_appdata == '':
		print('LOCALAPPDATA not defined')
		sys.exit(1)

	src_path = DOTFILES_DIR / 'src' / 'win-term-settings.json'
	dst_path = Path(local_appdata) / 'Packages' / 'Microsoft.WindowsTerminal_8wekyb3d8bbwe' / 'LocalState' / 'settings.json'
	src_path = str(src_path)
	dst_path = str(dst_path)

	with open(dst_path, 'r', encoding='UTF-8') as f:
		live_settings = json.loads(f.read())

		default_profile_guid = live_settings['defaultProfile']
		cmd_guid             = live_settings['profiles']['list'][0]['guid']

	if default_profile_guid == '' or cmd_guid == '':
		print('failed to get GUID of defaultProfile or cmd s')
		sys.exit(1)

	with open(src_path, 'r', encoding='UTF-8') as f:
		settings = f.read()
		settings = settings.replace('DEFAULT_PROFILE_GUID', default_profile_guid)
		settings = settings.replace('CMD_GUID',             cmd_guid)
		settings = settings.replace('SETUP_CMD_PATH',       str(HOME / 'setup.cmd').replace('\\', '\\\\'))

	with open(dst_path, 'w', encoding='UTF-8') as f:
		f.write(settings)

	print(f'copied {src_path} -> {dst_path}')

# =========================================================================== #
#     vim                                                                     #
# =========================================================================== #

def apply_vim():
	copy_file_to_home('.vimrc')

	subprocess.run(
		['vim', '-es', '-c', 'redir! > vim_rtp.txt', '-c', 'echo &runtimepath', '-c', 'redir END', '-c', 'quit!'],
		check=True,
	)

	if not os.path.isfile('vim_rtp.txt'):
		print('failed to get vim runtime path')
		sys.exit(1)

	with open('vim_rtp.txt', 'r', encoding='UTF-8') as f:
		vim_rtp = f.read().strip().split(',')[0]
		vim_rtp = Path(vim_rtp)

		copy_directory(
			DOTFILES_DIR / 'src' / 'vim' / 'swank-client',
			vim_rtp / 'swank-client',
		)

	os.remove('vim_rtp.txt')

# =========================================================================== #
#     lazygit                                                                 #
# =========================================================================== #

def apply_lazygit():
	result = subprocess.run(
		['lazygit', '--print-config-dir'],
		capture_output=True,
		text=True,
		check=True,
	)

	lazygit_cfg = result.stdout.strip()
	lazygit_cfg = Path(lazygit_cfg)

	copy_file(
		DOTFILES_DIR / 'src' / 'lazygit-config.yml',
		lazygit_cfg / 'config.yml',
	)

# =========================================================================== #
#     main                                                                    #
# =========================================================================== #

if SYSTEM == 'Darwin':
	copy_file_to_home('.zsh_prompt')
	copy_file_to_home('.zshenv')
elif SYSTEM == 'Windows':
	copy_file_to_home('setup.cmd')
	apply_terminal_windows()

apply_vim()
apply_lazygit()
