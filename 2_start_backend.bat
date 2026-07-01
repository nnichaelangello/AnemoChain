@echo off
title Backend Server AI (Port 8000)
echo ========================================================
echo             MEMULAI BACKEND SERVER PRISMA
echo ========================================================
cd Backend
uvicorn main:app --host 0.0.0.0 --port 8000
pause
