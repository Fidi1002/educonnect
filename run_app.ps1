Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "        EduConnect Automation Run/Build/Test Script" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Jalankan Aplikasi (flutter run)"
Write-Host "2. Jalankan Pengujian (flutter test)"
Write-Host "3. Build APK Rilis (flutter build apk)"
Write-Host "4. Analisis Statis (flutter analyze)"
Write-Host ""
$pilihan = Read-Host "Pilih aksi (1-4)"

$SUPABASE_URL = ""
$SUPABASE_ANON_KEY = ""

if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $key, $value = $line.Split("=", 2)
            $key = $key.Trim()
            $value = $value.Trim()
            if ($key -eq "SUPABASE_URL") { $SUPABASE_URL = $value }
            elseif ($key -eq "SUPABASE_ANON_KEY") { $SUPABASE_ANON_KEY = $value }
        }
    }
}

if (-not $SUPABASE_URL -or -not $SUPABASE_ANON_KEY) {
    Write-Host "Error: SUPABASE_URL / SUPABASE_ANON_KEY tidak ditemukan di .env" -ForegroundColor Red
    exit 1
}

# Set environment variables for tests
$env:SUPABASE_URL = $SUPABASE_URL
$env:SUPABASE_ANON_KEY = $SUPABASE_ANON_KEY

if ($pilihan -eq "1") {
    Write-Host "Menjalankan aplikasi dengan dart-define..." -ForegroundColor Green
    flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
} elseif ($pilihan -eq "2") {
    Write-Host "Menjalankan seluruh pengujian unit dan integrasi..." -ForegroundColor Green
    flutter test
} elseif ($pilihan -eq "3") {
    Write-Host "Membangun APK Rilis..." -ForegroundColor Green
    flutter build apk --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
} elseif ($pilihan -eq "4") {
    Write-Host "Menganalisis kualitas kode..." -ForegroundColor Green
    flutter analyze
} else {
    Write-Host "Pilihan tidak valid." -ForegroundColor Red
}
