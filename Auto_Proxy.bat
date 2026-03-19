@echo off
title Proxy_ADB_Loop
chcp 65001 >nul
echo ===================================================
echo    Automatic Tunnel (ADB Port Forward)
echo ===================================================
:loop
echo.
echo [WAITING] Connect your phone via USB...
adb -d wait-for-device

echo [FOUND] Phone connected! Clearing old ports...
adb forward --remove-all

echo [FORWARDING] Starting tunnel (PC: 10808 -^> Phone: 10808)...
adb -d forward tcp:10808 tcp:10808

echo [READY] Tunnel is active. Waiting for cable disconnection...
adb -d wait-for-disconnect

echo [DISCONNECTED] Cable disconnected.
goto loop