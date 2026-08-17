@echo off
powershell.exe -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*watchdog.js*' -or $_.CommandLine -like '*src\\index.js*' -or $_.CommandLine -like '*src/index.js*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"
echo Antigravity Bot has been stopped.
