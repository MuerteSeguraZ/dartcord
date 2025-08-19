@echo off

git add --all

set MSG=%1
if "%MSG%"=="" set MSG=Invite Management Update

git commit -m "%MSG%"

git push origin main

pause
