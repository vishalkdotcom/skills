$ErrorActionPreference = 'Stop'

# --- customize ---
$startUrl = 'http://localhost:3001/next/login'
$outDir = $PSScriptRoot   # run-windows-script.sh copies this file to Videos/<slug>/run.ps1
$videoFile = Join-Path $outDir 'demo.webm'
# --- end customize ---

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
. (Join-Path $PSScriptRoot 'parse-playwright-result.ps1')

playwright-cli close-all 2>$null
playwright-cli open $startUrl --browser=chromium
playwright-cli resize 1920 1080
playwright-cli video-start $videoFile
playwright-cli video-chapter 'Start' --description='Opening scenario entry point'

# --- scenario steps ---
# playwright-cli fill 'input[name="username"]' $env:WOVO_TEST_USER
# playwright-cli goto 'http://localhost:3001/next/...'
Start-Sleep -Seconds 3
# --- end steps ---

playwright-cli snapshot --filename="$outDir\snapshot.yml"
playwright-cli screenshot --filename="$outDir\screenshot.png"

$title = Get-PlaywrightResult -RawOutput ((playwright-cli eval 'document.title' | Out-String).Trim())

playwright-cli video-stop
playwright-cli close-all

Write-Output "title=$title"
Write-Output "video=$videoFile"
Write-Output 'SCENARIO_OK'
