@echo off
setlocal
title OmniRoute Launcher (port 20130)
rem ============================================================
rem  OmniRoute launcher - run on port 20130
rem  (port 20128 dipakai VansRouter / 9Router, jangan diganggu)
rem
rem  PERBAIKAN 2026-08-15:
rem  - BASE_URL/OMNIROUTE_BASE_URL diarahkan ke 127.0.0.1:20130
rem    (bukan localhost:20128 lagi) supaya tidak bentrok dengan
rem    VansRouter dan dashboard tidak timeout.
rem  - Akses dashboard via http://127.0.0.1:20130 (cookie session
rem    terpisah dari localhost punya VansRouter -> tidak perlu
rem    login ulang terus-menerus).
rem  - Spawn via PowerShell Start-Process agar bersih & andal.
rem ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-omniroute.ps1"
exit /b 0
