@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pull.ps1"
echo.
echo [DONE] 已完成拉取。按任意键关闭…
pause >nul
endlocal