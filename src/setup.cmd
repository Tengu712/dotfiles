@echo off

chcp 65001 >nul

set EDITOR=vim
set "PATH=%PATH%;%USERPROFILE%\.executables"
set "PATH=%LOCALAPPDATA%\mise\shims;%PATH%"

for /f "delims=" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find **\vcvars64.bat') do (
	set "VCVARS_PATH=%%i"
)
call "%VCVARS_PATH%"

doskey cdoc=cd %USERPROFILE%\Documents

doskey af=search af
doskey ag=search ag

doskey vf=vim -c VF
doskey vg=vim -c VG

doskey lg=lazygit $*
