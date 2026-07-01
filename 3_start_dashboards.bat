@echo off
title Web Dashboards (Port 8002)
echo ========================================================
echo       MEMULAI WEB DASHBOARDS (HOSPITAL & EXPLORER)
echo ========================================================
echo.
echo 1. Hospital Dashboard (EHR): http://localhost:8002/hospital
echo 2. Blockchain Explorer     : http://localhost:8002/explorer
echo.
cd Dashboards
uvicorn main:app --host 0.0.0.0 --port 8002
pause
