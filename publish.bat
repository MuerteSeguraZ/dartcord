@echo off

git add --all

set MSG=%1
if "%MSG%"=="" set MSG=Category and Webhook management update

git commit -m "%MSG%"

git push origin main

pause
