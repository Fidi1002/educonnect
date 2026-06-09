@echo off
echo ========================================================
echo         EduConnect Automation Run/Build/Test Script
echo ========================================================
echo.
echo 1. Jalankan Aplikasi (flutter run)
echo 2. Jalankan Pengujian (flutter test)
echo 3. Build APK Rilis (flutter build apk)
echo 4. Analisis Statis (flutter analyze)
echo.
set /p pilihan="Pilih aksi (1-4): "

if exist .env (
    for /f "usebackq tokens=1,2 delims==" %%i in (".env") do (
        if "%%i"=="SUPABASE_URL" set SUPABASE_URL=%%j
        if "%%i"=="SUPABASE_ANON_KEY" set SUPABASE_ANON_KEY=%%j
    )
)

if "%SUPABASE_URL%"=="" (
    echo Error: SUPABASE_URL tidak ditemukan di .env
    exit /b 1
)
if "%SUPABASE_ANON_KEY%"=="" (
    echo Error: SUPABASE_ANON_KEY tidak ditemukan di .env
    exit /b 1
)

if "%pilihan%"=="1" (
    echo Menjalankan aplikasi dengan dart-define...
    flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
) else if "%pilihan%"=="2" (
    echo Menjalankan seluruh pengujian unit dan integrasi...
    set SUPABASE_URL=%SUPABASE_URL%
    set SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
    flutter test
) else if "%pilihan%"=="3" (
    echo Membangun APK Rilis...
    flutter build apk --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
) else if "%pilihan%"=="4" (
    echo Menganalisis kualitas kode...
    flutter analyze
) else (
    echo Pilihan tidak valid.
)
pause
