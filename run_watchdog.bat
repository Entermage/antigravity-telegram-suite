@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist logs mkdir logs
where node >nul 2>nul
if %errorlevel% equ 0 (
    node src\watchdog.js >> logs\watchdog.log 2>&1
) else (
    "%ProgramFiles%\nodejs\node.exe" src\watchdog.js >> logs\watchdog.log 2>&1
)
