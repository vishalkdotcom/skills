# Requires: herdr on PATH (or HERDR_BIN_PATH).
# Read an occupant's ctx% for the session-policy budget override.
# Primary: pane metadata token `ctx` (statusline.js → report-metadata).
# Fallback: scrape the TUI statusline from `agent read --source visible`.
param(
    [Parameter(Mandatory = $true)]
    [string]$Name
)

$ErrorActionPreference = 'Stop'
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }

function Invoke-HerdrJson {
    $output = & $herdr @args
    $text = ($output | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw "herdr $($args -join ' ') failed ($LASTEXITCODE): $text" }
    try {
        return $text | ConvertFrom-Json
    }
    catch {
        throw "herdr $($args -join ' '): not JSON: $text"
    }
}

$agent = (Invoke-HerdrJson agent get $Name).result.agent
if ($null -eq $agent) { throw "no agent named $Name" }

$paneId = $agent.pane_id
$sessionId = $agent.agent_session.value
$pct = $null
$source = 'unknown'

$tok = $agent.tokens.ctx
if ($tok -match '^\d+$') {
    $pct = [int]$tok
    $source = 'metadata'
}
if ($null -eq $pct) {
    $pane = (Invoke-HerdrJson pane get $paneId).result.pane
    $tok = $pane.tokens.ctx
    if ($tok -match '^\d+$') {
        $pct = [int]$tok
        $source = 'metadata'
    }
}

if ($null -eq $pct) {
    $text = & $herdr agent read $Name --source visible --format text | Out-String
    if ($LASTEXITCODE -ne 0) { throw "herdr agent read $Name failed ($LASTEXITCODE)" }
    $hits = [regex]::Matches($text, 'ctx[^\n]*?(\d+)\s*%')
    if ($hits.Count -gt 0) {
        $pct = [int]$hits[$hits.Count - 1].Groups[1].Value
        $source = 'scrape'
    }
}

$result = [ordered]@{
    name       = $Name
    pane_id    = $paneId
    session_id = $sessionId
    pct        = $pct
    source     = $source
}
$result | ConvertTo-Json -Compress
if ($null -eq $pct) { exit 2 }
