@echo off
title Membangun File APK PRISMA
echo ========================================================
echo                MEMBANGUN FILE APK (.apk)
echo ========================================================
echo Memulai proses kompilasi Build APK. Ini akan memakan waktu beberapa menit...
cd Mobile
flutter build apk --release
echo.
echo ========================================================
echo File APK berhasil dibuat! 
echo Anda bisa mengambilnya di: Mobile\build\app\outputs\flutter-apk\app-release.apk
echo Pindahkan file ini ke HP juri untuk demonstrasi.
echo ========================================================
pause
