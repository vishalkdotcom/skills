$ErrorActionPreference = 'Stop'

# Tier B template — pair with demo-template-flow.js (copy both to wovo-browser-qa/scenarios/<slug>/).
$outDir = $PSScriptRoot
$videoFile = Join-Path $outDir 'demo.webm'
$flowFile = Join-Path $outDir 'flow.js'

if (-not (Test-Path $flowFile)) {
  throw "Missing flow.js beside run.ps1. Copy scripts/demo-template-flow.js as flow.js"
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$env:DEMO_VIDEO_PATH = $videoFile
$env:DEMO_LOGIN_URL = if ($env:DEMO_LOGIN_URL) { $env:DEMO_LOGIN_URL } else { 'http://localhost:3001/next/login' }

playwright-cli close-all 2>$null
playwright-cli run-code --filename="$flowFile"

if (-not (Test-Path $videoFile)) {
  throw "Video not produced: $videoFile"
}

$size = (Get-Item $videoFile).Length
Write-Output "video=$videoFile"
Write-Output "videoBytes=$size"

if ($size -lt 100000) {
  throw "Video suspiciously small ($size bytes) — check screencast size 1920x1080"
}

Write-Output 'SCENARIO_OK'
