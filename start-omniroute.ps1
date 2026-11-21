# OmniRoute launcher (port 20130) - dipanggil dari start-omniroute.bat
# Menggunakan Start-Process agar spawn bersih tanpa masalah quoting.
$port = 20130
$wrapper = Join-Path $PSScriptRoot "run-omniroute-serve.cmd"
$logdir = Join-Path $env:USERPROFILE ".omniroute"
if (-not (Test-Path $logdir)) { New-Item -ItemType Directory -Path $logdir -Force | Out-Null }

# cek port sudah jalan?
$listening = netstat -ano | Select-String -Pattern ":20130 .*LISTENING"
if ($listening) {
    Write-Host "[OK] OmniRoute sudah berjalan di port 20130."
} else {
    Write-Host "[..] Menjalankan OmniRoute di port $port ..."
    Start-Process -WindowStyle Minimized -FilePath "cmd.exe" -ArgumentList "/c", "call `"$wrapper`""
    # tunggu sampai port siap (max 90 detik)
    for ($i = 0; $i -lt 90; $i++) {
        Start-Sleep -Seconds 1
        if (netstat -ano | Select-String -Pattern ":20130 .*LISTENING") { break }
    }
}
Write-Host ""
Write-Host "============================================================"
Write-Host " OmniRoute siap!"
Write-Host " Dashboard : http://127.0.0.1:20130/dashboard"
Write-Host " API       : http://127.0.0.1:20130/v1"
Write-Host "============================================================"
