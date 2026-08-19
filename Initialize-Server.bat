@echo off
echo Starting Server Initialization...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Initialize-Server.ps1"
echo.
pause
