@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0init.ps1"
echo.
echo [DONE] 初始化完成。按任意键关闭…
pause >nul
endlocal