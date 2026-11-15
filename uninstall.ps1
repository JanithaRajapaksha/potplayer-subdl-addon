# SubDL PotPlayer Extension Uninstaller
# PowerShell Script

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   SubDL Subtitle Add-on Uninstaller                      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$potPaths = @(
    "C:\Program Files\DAUM\PotPlayer\Extension\Subtitle\Search",
    "C:\Program Files (x86)\DAUM\PotPlayer\Extension\Subtitle\Search"
)

$targetFolder = $null
foreach ($path in $potPaths) {
    if (Test-Path $path) {
        $targetFolder = $path
        break
    }
}

if (-not $targetFolder) {
    Write-Host "[ERROR] Could not locate PotPlayer extension folder." -ForegroundColor Red
    Exit 1
}

$dstScript = Join-Path $targetFolder "SubtitleSearch - SubDL.as"
$dstIcon   = Join-Path $targetFolder "SubtitleSearch - SubDL.ico"
$backupScript = "$dstScript.bak"

if (Test-Path $backupScript) {
    Write-Host "[*] Restoring original SubDL backup script..." -ForegroundColor Yellow
    Copy-Item $backupScript $dstScript -Force
    Remove-Item $backupScript -Force
    Write-Host "[SUCCESS] Original script restored successfully." -ForegroundColor Green
} else {
    if (Test-Path $dstScript) {
        Remove-Item $dstScript -Force
        Write-Host "[*] Removed SubtitleSearch - SubDL.as" -ForegroundColor Yellow
    }
    Write-Host "[SUCCESS] SubDL extension uninstalled." -ForegroundColor Green
}

Write-Host ""
pause
