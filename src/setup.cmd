@echo off

chcp 65001 >nul

set EDITOR=vim
set PATH=%PATH%;%USERPROFILE%\.executables

for /f "delims=" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find **\vcvars64.bat') do (
	set "VCVARS_PATH=%%i"
)
call "%VCVARS_PATH%"

doskey af=search af
doskey ag=search ag

doskey gs=git status $*
doskey gl=git log $*
doskey ga=git add -A $*
doskey gm=git commit -m $*
doskey gpush=git push origin HEAD $*
doskey groot=git commit --allow-empty -m "root commit" $*
doskey gsuir=git submodule update --init --recursive $*

doskey vf=search af ^| vim -c OpenFromPipe - --not-a-term
doskey vg=search ag ^| vim -c OpenFromPipe - --not-a-term

doskey lg=lazygit $*
