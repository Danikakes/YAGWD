@echo off
echo ============================================================
echo AUTOMATED MONITOR BUILD SYSTEM
echo ============================================================
echo.
echo This will build your custom monitor EXE using build-config.ini
echo.
echo Make sure you've edited build-config.ini first!
echo.
pause

powershell -ExecutionPolicy Bypass -File ".\build-monitor.ps1"
