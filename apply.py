import hashlib
import json
import os
import platform
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


def clone_git(url, dst):
	if not (dst / '.git').exists():
		dst.parent.mkdir(parents=True, exist_ok=True)
		subprocess.run(['git', 'clone', '--depth', '1', url, dst], check=True)
		print(f'cloned {url} -> {dst}')
		return

	remote_head = subprocess.run(['git', 'ls-remote', url, 'HEAD'], capture_output=True, text=True, check=True).stdout.split()[0]
	local_head  = subprocess.run(['git', '-C', dst, 'rev-parse', 'HEAD'], capture_output=True, text=True, check=True).stdout.strip()

	if remote_head == local_head:
		print(f'skipped {url} -> {dst} (unchanged)')
		return

	subprocess.run(['git', '-C', dst, 'fetch', '--depth', '1', 'origin'], check=True)
	subprocess.run(['git', '-C', dst, 'reset', '--hard', 'FETCH_HEAD'], check=True)
	print(f'updated {url} -> {dst}')


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


def apply_zshrc():
	if SYSTEM != 'Darwin':
		print('skipped applying .zshrc')
		return

	zshrc_path    = HOME_DIR / '.zshrc'
	template_path = SRC_DIR / '.zshrc.template'
	template      = template_path.read_text().rstrip('\n') if template_path.exists() else ''
	src_path      = SRC_DIR / '.zshrc'
	src           = src_path.read_text().rstrip('\n')

	zshrc_path.write_text(f'{template}\n\n{src}\n' if template else f'{src}\n')
	print(f'set {src_path} -> {zshrc_path}')


def apply_ghostty():
	if SYSTEM != 'Darwin':
		print('skipped applying config.ghostty')
		return

	copy_file(SRC_DIR / 'config.ghostty', HOME_DIR / 'Library' / 'Application Support' / 'com.mitchellh.ghostty' / 'config.ghostty')


def apply_setup_cmd():
	if SYSTEM != 'Windows':
		print('skipped applying setup.cmd')
		return

	copy_file(SRC_DIR / 'setup.cmd', HOME_DIR / 'setup.cmd')


def apply_windows_terminal():
	if SYSTEM != 'Windows':
		print('skipped applying Windows terminal settings')
		return

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
#     tools                                                                   #
# =========================================================================== #


def apply_system_prompt():
	copy_file(SRC_DIR / 'SYSTEM_PROMPT.md', HOME_DIR / '.claude' / 'CLAUDE.md')
	copy_file(SRC_DIR / 'SYSTEM_PROMPT.md', HOME_DIR / '.codex' / 'AGENTS.md')


def apply_git():
	copy_file(SRC_DIR / 'git' / 'ignore', HOME_DIR / '.config' / 'git' / 'ignore')
	copy_file(SRC_DIR / 'git' / 'config', HOME_DIR / '.config' / 'git' / 'config')


def apply_vim():
	copy_file(SRC_DIR / '.vimrc', HOME_DIR / '.vimrc')

	subprocess.run(
		['vim', '-es', '--noplugin', '-c', 'redir! > vim_rtp.txt', '-c', 'echo &runtimepath', '-c', 'redir END', '-c', 'quit!'],
		check=True,
	)

	if not os.path.isfile('vim_rtp.txt'):
		print('failed to get vim runtime path')
		sys.exit(1)

	with open('vim_rtp.txt', 'r', encoding='UTF-8') as f:
		vim_rtp = f.read().strip().split(',')[0]
		vim_rtp = Path(vim_rtp)
	os.remove('vim_rtp.txt')

	for src in (SRC_DIR / 'vim').iterdir():
		if src.name == '.DS_Store':
			continue
		if src.is_dir():
			copy_directory(src, vim_rtp / src.name)
		else:
			copy_file(src, vim_rtp / src.name)

	clone_git(
		'https://github.com/lambdalisue/vim-fern',
		vim_rtp / 'pack' / 'plugins' / 'start' / 'vim-fern',
	)
	clone_git(
		'https://github.com/lambdalisue/vim-fern-git-status',
		vim_rtp / 'pack' / 'plugins' / 'start' / 'vim-fern-git-status',
	)
	clone_git(
		'https://github.com/lambdalisue/nerdfont.vim',
		vim_rtp / 'pack' / 'plugins' / 'start' / 'nerdfont.vim',
	)
	clone_git(
		'https://github.com/lambdalisue/vim-fern-renderer-nerdfont',
		vim_rtp / 'pack' / 'plugins' / 'start' / 'vim-fern-renderer-nerdfont',
	)
	clone_git(
		'https://github.com/airblade/vim-gitgutter',
		vim_rtp / 'pack' / 'plugins' / 'start' / 'vim-gitgutter',
	)


def apply_mise():
	copy_file(SRC_DIR / 'mise.toml', HOME_DIR / '.config' / 'mise' / 'config.toml')
	subprocess.run(['mise', 'install'], check=True)


def apply_lazygit():
	result = subprocess.run(
		['lazygit', '--print-config-dir'],
		capture_output=True,
		text=True,
		check=True,
	)

	lazygit_cfg = result.stdout.strip()
	lazygit_cfg = Path(lazygit_cfg)

	copy_file(SRC_DIR / 'lazygit-config.yml', lazygit_cfg / 'config.yml')


def install_util_tools():
	ext = '.exe' if SYSTEM == 'Windows' else ''
	compile_rust(SRC_DIR / 'cmd' / 'cddrs.rs',      EXE_DIR / f'cddrs{ext}')
	compile_rust(SRC_DIR / 'cmd' / 'search.rs',     EXE_DIR / f'search{ext}')
	compile_rust(SRC_DIR / 'cmd' / 'rg-preview.rs', EXE_DIR / f'rg-preview{ext}')


# =========================================================================== #
#     main                                                                    #
# =========================================================================== #


apply_zshrc()
apply_ghostty()
apply_setup_cmd()
apply_windows_terminal()
apply_system_prompt()
apply_git()
apply_vim()
apply_mise()
apply_lazygit()
install_util_tools()
