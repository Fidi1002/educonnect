param(
  [string]$ProjectId = "aplikasi-educonnect-id"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command firebase.cmd -ErrorAction SilentlyContinue)) {
  throw "firebase CLI belum tersedia. Jalankan: npm.cmd install -g firebase-tools"
}

$loginResult = cmd /c "firebase.cmd login:list 2>&1"
$hasAccount = $loginResult -notmatch "No authorized accounts"
$hasToken = -not [string]::IsNullOrWhiteSpace($env:FIREBASE_TOKEN)

if (-not $hasAccount -and -not $hasToken) {
  throw "Belum login Firebase CLI. Jalankan 'firebase login' atau set FIREBASE_TOKEN."
}

$deployArgs = @(
  "deploy",
  "--project", $ProjectId,
  "--only", "firestore:rules,firestore:indexes,storage"
)

if ($hasToken) {
  $deployArgs += @("--token", $env:FIREBASE_TOKEN)
}

Write-Host "Deploying rules and indexes to $ProjectId ..."
firebase.cmd @deployArgs
if ($LASTEXITCODE -ne 0) {
  throw "Deploy gagal dengan exit code $LASTEXITCODE."
}
Write-Host "Deploy selesai."
