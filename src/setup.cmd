@echo off

chcp 65001 >nul

set EDITOR=vim
set PATH=%PATH%;%USERPROFILE%\.executables
rem find and set vcvarsall.bat

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
