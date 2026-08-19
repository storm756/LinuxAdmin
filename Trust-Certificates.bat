@echo off
echo Starting Certificate Trust Initialization...
:: Request Administrator privileges and run the PowerShell script
powershell.exe -Command "Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -NoProfile -File \"%~dp0Trust-Certificates.ps1\"' -Verb RunAs"
echo.
echo If the Administrator prompt appeared, the script is running in a new window.
echo You can close this window.
pause
