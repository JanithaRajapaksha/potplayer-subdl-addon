# SubDL PotPlayer Extension Installer
# PowerShell Script

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   SubDL Subtitle Add-on Installer for Daum PotPlayer     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Locate PotPlayer installation folder
$potPaths = @(
    "C:\Program Files\DAUM\PotPlayer",
    "C:\Program Files (x86)\DAUM\PotPlayer"
)

# Also check Registry
try {
    $reg = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\PotPlayer64" -ErrorAction SilentlyContinue
    if ($reg -and $reg.DisplayIcon) {
        $regFolder = Split-Path $reg.DisplayIcon -Parent
        if ($regFolder -and (Test-Path $regFolder)) {
            $potPaths = @($regFolder) + $potPaths
        }
    }
} catch {}

$targetFolder = $null
foreach ($path in $potPaths) {
    if (Test-Path "$path\Extension\Subtitle\Search") {
        $targetFolder = "$path\Extension\Subtitle\Search"
        break
    } elseif (Test-Path $path) {
        $subFolder = "$path\Extension\Subtitle\Search"
        New-Item -ItemType Directory -Path $subFolder -Force | Out-Null
        $targetFolder = $subFolder
        break
    }
}

if (-not $targetFolder) {
    Write-Host "[ERROR] Could not automatically locate PotPlayer installation folder." -ForegroundColor Red
    Write-Host "Please manually copy 'SubtitleSearch - SubDL.as' and 'SubtitleSearch - SubDL.ico' to:" -ForegroundColor Yellow
    Write-Host "C:\Program Files\DAUM\PotPlayer\Extension\Subtitle\Search\" -ForegroundColor Yellow
    Exit 1
}

Write-Host "[+] PotPlayer Extension Folder found:" -ForegroundColor Green
Write-Host "    $targetFolder" -ForegroundColor Gray
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcScript = Join-Path $scriptDir "SubtitleSearch - SubDL.as"
$srcIcon   = Join-Path $scriptDir "SubtitleSearch - SubDL.ico"

# 2. Backup existing script if present
$dstScript = Join-Path $targetFolder "SubtitleSearch - SubDL.as"
$dstIcon   = Join-Path $targetFolder "SubtitleSearch - SubDL.ico"

try {
    if (Test-Path $dstScript) {
        $backupPath = "$dstScript.bak"
        Write-Host "[*] Backing up existing SubDL script to:" -ForegroundColor Yellow
        Write-Host "    $backupPath" -ForegroundColor Gray
        Copy-Item $dstScript $backupPath -Force
    }

    # 3. Copy new files
    Write-Host "[*] Installing enhanced SubDL extension..." -ForegroundColor Cyan
    Copy-Item $srcScript $dstScript -Force
    if (Test-Path $srcIcon) {
        Copy-Item $srcIcon $dstIcon -Force
    }
} catch {
    Write-Host ""
    Write-Host "[ERROR] Permission denied writing to $targetFolder" -ForegroundColor Red
    Write-Host "Please right-click 'install.bat' and select 'Run as Administrator'." -ForegroundColor Yellow
    Exit 1
}

Write-Host ""
Write-Host "[SUCCESS] SubDL Extension successfully installed!" -ForegroundColor Green
Write-Host ""
Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "HOW TO CONFIGURE IN POTPLAYER:" -ForegroundColor White
Write-Host "1. Open PotPlayer." -ForegroundColor White
Write-Host "2. Press F5 (Preferences)." -ForegroundColor White
Write-Host "3. Navigate to: Extensions -> Subtitle Search." -ForegroundColor White
Write-Host "4. Select 'SubDL' from the list and click 'Account / Configure'." -ForegroundColor White
Write-Host "5. Paste your free SubDL API key (get one from https://subdl.com/panel)." -ForegroundColor White
Write-Host "6. Click OK." -ForegroundColor White
Write-Host ""
Write-Host "Press Alt + S while playing any video to search and auto-load subtitles!" -ForegroundColor Cyan
Write-Host "----------------------------------------------------------" -ForegroundColor Gray
