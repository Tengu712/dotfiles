import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

os.chdir(os.path.dirname(os.path.abspath(__file__)))

SYSTEM    = platform.system()
HOME_DIR  = Path.home()
EXE_DIR   = HOME_DIR / '.executables'
SRC_DIR   = Path(__file__).resolve().parent / 'src'
CACHE_DIR = Path(__file__).resolve().parent / '.cache'

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
	copy_file(SRC_DIR / path, HOME_DIR / path)

def compile_rust(src, dst):
	dst.parent.mkdir(parents=True, exist_ok=True)
	CACHE_DIR.mkdir(parents=True, exist_ok=True)

	src_hash   = hashlib.blake2b(src.read_bytes()).hexdigest()
	cache_file = CACHE_DIR / f'{src.name}.hash'

	if dst.exists() and cache_file.exists() and cache_file.read_text() == src_hash:
		print(f'skipped {src} -> {dst} (unchanged)')
		return

	subprocess.run(
		[
			'rustc',
			'-C', 'opt-level=z',
			'-C', 'lto=fat',
			'-C', 'codegen-units=1',
			'-C', 'panic=abort',
			'-C', 'strip=symbols',
			'-o', dst, src,
		],
		check=True,
	)
	cache_file.write_text(src_hash)
	print(f'compiled {src} -> {dst}')

# =========================================================================== #
#     terminal                                                                #
# =========================================================================== #

def embed_zshrc():
	MARK_START = '# MARK: start dotfiles'
	MARK_END   = '# MARK: end dotfiles'

	zshrc_path = Path(HOME_DIR / '.zshrc')
	zshrc      = zshrc_path.read_text().rstrip('\n') if zshrc_path.exists() else ''
	src_path   = Path(SRC_DIR / '.zshrc')
	src        = src_path.read_text().rstrip('\n')
	block      = f'{MARK_START}\n{src}\n{MARK_END}\n'
	pattern = re.compile(rf"^{re.escape(MARK_START)}$.*?^{re.escape(MARK_END)}$", re.M | re.S)

	if pattern.search(zshrc):
		zshrc = pattern.sub(lambda _: block, zshrc, count=1)
		if not zshrc.endswith('\n'):
			zshrc += '\n'
	else:
		zshrc += '\n\n' + block

	zshrc_path.write_text(zshrc)
	print(f'set {src_path} -> {zshrc_path}')

def apply_sh():
	if SYSTEM == 'Darwin':
		embed_zshrc()
		compile_rust(SRC_DIR / 'cmd' / 'search.rs', EXE_DIR / 'search')
		compile_rust(SRC_DIR / 'cmd' / 'rg-preview.rs', EXE_DIR / 'rg-preview')
	elif SYSTEM == 'Windows':
		copy_file_to_home('setup.cmd')
		compile_rust(SRC_DIR / 'cmd' / 'search.rs', EXE_DIR / 'search.exe')
		compile_rust(SRC_DIR / 'cmd' / 'rg-preview.rs', EXE_DIR / 'rg-preview.exe')

def apply_terminal_windows():
	local_appdata = os.environ['LOCALAPPDATA']
	if local_appdata == '':
		print('LOCALAPPDATA not defined')
		sys.exit(1)

	src_path = SRC_DIR / 'win-term-settings.json'
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
		settings = settings.replace('SETUP_CMD_PATH',       str(HOME_DIR / 'setup.cmd').replace('\\', '\\\\'))

	with open(dst_path, 'w', encoding='UTF-8') as f:
		f.write(settings)

	print(f'copied {src_path} -> {dst_path}')

# =========================================================================== #
#     Coding Agents                                                           #
# =========================================================================== #

def apply_system_prompt():
	copy_file(SRC_DIR / 'SYSTEM_PROMPT.md', HOME_DIR / '.claude' / 'CLAUDE.md')
	copy_file(SRC_DIR / 'SYSTEM_PROMPT.md', HOME_DIR / '.codex' / 'AGENTS.md')

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
			SRC_DIR / 'vim' / 'line-jumper',
			vim_rtp / 'line-jumper',
		)
		copy_directory(
			SRC_DIR / 'vim' / 'search',
			vim_rtp / 'search',
		)
		copy_directory(
			SRC_DIR / 'vim' / 'surround',
			vim_rtp / 'surround',
		)
		copy_directory(
			SRC_DIR / 'vim' / 'swank-client',
			vim_rtp / 'swank-client',
		)

	os.remove('vim_rtp.txt')

# =========================================================================== #
#     mise                                                                    #
# =========================================================================== #

def apply_mise():
	copy_file(SRC_DIR / 'mise.toml', HOME_DIR / '.config' / 'mise' / 'config.toml')

	subprocess.run(['mise', 'install'], check=True)

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
		SRC_DIR / 'lazygit-config.yml',
		lazygit_cfg / 'config.yml',
	)

# =========================================================================== #
#     main                                                                    #
# =========================================================================== #

apply_sh()
if SYSTEM == 'Windows': apply_terminal_windows()
apply_system_prompt()
apply_vim()
apply_mise()
apply_lazygit()
