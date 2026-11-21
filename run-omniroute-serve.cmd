@echo off
rem ============================================================
rem  OmniRoute server wrapper - dipanggil oleh start-omniroute.bat
rem  Jalan di port 20130, terisolasi dari VansRouter (20128)
rem ============================================================
set "PORT=20130"
set "BASE_URL=http://127.0.0.1:20130"
set "OMNIROUTE_BASE_URL=http://127.0.0.1:20130"
set "NEXT_PUBLIC_BASE_URL=http://127.0.0.1:20130"
set "DASHBOARD_PORT=20130"
set "API_PORT=20130"
set "LOGDIR=%USERPROFILE%\.omniroute"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
omniroute.cmd serve --port 20130 --no-open >> "%LOGDIR%\omniroute.log" 2>&1
