@echo off
title Hyperledger Blockchain Node (Port 8001)
echo ========================================================
echo        MEMULAI JARINGAN HYPERLEDGER FABRIC NODE
echo ========================================================
cd Blockchain
uvicorn hyperledger_node:app --host 0.0.0.0 --port 8001
pause
