@echo off

chcp 65001 >nul

set EDITOR=vim

doskey gs=git status $*
doskey gl=git log $*
doskey ga=git add -A $*
doskey gm=git commit -m $*
doskey gpush=git push origin HEAD $*
doskey groot=git commit --allow-empty -m "root commit" $*
doskey gsuir=git submodule update --init --recursive $*

doskey lg=lazygit $*
