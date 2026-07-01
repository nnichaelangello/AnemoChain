@echo off
title Database Admin (Port 8080)
echo ========================================================
echo       MEMULAI DATABASE ADMIN (SQLITE-WEB)
echo ========================================================
echo.
echo Akses Database Admin di: http://localhost:8080
echo.
sqlite_web Backend\anemia_records.db --port 8080
pause
