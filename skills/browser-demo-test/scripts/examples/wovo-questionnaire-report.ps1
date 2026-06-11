$ErrorActionPreference = 'Stop'

$outDir = $PSScriptRoot
$videoFile = Join-Path $outDir 'questionnaire-report-demo.webm'
$loginUrl = 'http://localhost:3001/next/login'
$questionnaireId = if ($env:WOVO_QUESTIONNAIRE_ID) { $env:WOVO_QUESTIONNAIRE_ID } else { '47807c75-4e21-4eb9-a47a-4a6ab3c9cd08' }
$clientIds = if ($env:WOVO_CLIENT_IDS) { $env:WOVO_CLIENT_IDS } else { '137089' }
$reportUrl = "http://localhost:3001/next/questionnaire/info?id=$questionnaireId&section=report&viewMode=table&groupBy=company&responseType=unique&responseSource=url&clientIds=$clientIds"
$username = if ($env:WOVO_TEST_USER) { $env:WOVO_TEST_USER } else { 'vishal_admin' }
$password = if ($env:WOVO_TEST_PASSWORD) { $env:WOVO_TEST_PASSWORD } else { 'Wovo@123' }

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
. (Join-Path $PSScriptRoot 'parse-playwright-result.ps1')

playwright-cli close-all 2>$null
playwright-cli open $loginUrl --browser=chromium
playwright-cli resize 1920 1080
playwright-cli video-start $videoFile --size=1920x1080
playwright-cli video-chapter 'Login' --description='Dev login form'

playwright-cli fill 'input[name="username"]' $username
playwright-cli fill 'input[name="password"]' $password
playwright-cli click 'button[type="submit"]'
Start-Sleep -Seconds 5

playwright-cli video-chapter 'Questionnaire report' --description='Table view groupBy=company'
playwright-cli goto $reportUrl
Start-Sleep -Seconds 15

playwright-cli snapshot --filename="$outDir\report-snapshot.yml"
playwright-cli screenshot --filename="$outDir\report-screenshot.png"
playwright-cli console error

$url = Get-PlaywrightResult -RawOutput ((playwright-cli eval 'window.location.href' | Out-String).Trim())
$gridCountText = Get-PlaywrightResult -RawOutput ((playwright-cli eval 'document.querySelectorAll("[role=grid], table").length' | Out-String).Trim())
$errorVisible = Get-PlaywrightResult -RawOutput ((playwright-cli eval 'document.body.innerText.includes("Login failed") || document.body.innerText.includes("Something went wrong")' | Out-String).Trim())

playwright-cli video-stop
playwright-cli close-all

Write-Output "url=$url"
Write-Output "gridCount=$gridCountText"
Write-Output "errorVisible=$errorVisible"
Write-Output "video=$videoFile"

if ($url -notmatch 'questionnaire/info') {
  throw "Did not reach questionnaire report page. URL: $url"
}

$gridCount = [int]$gridCountText
if ($gridCount -lt 1) {
  throw "Expected at least one grid/table on report page, got: $gridCount"
}

if ($errorVisible -eq 'true') {
  throw 'Page shows a login failure or error state.'
}

Write-Output 'SCENARIO_OK'
