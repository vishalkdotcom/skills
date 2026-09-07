# Requires: herdr on PATH (or HERDR_BIN_PATH), server running.
# Ensures workspace + tabs + labelled idle shells from layout.json. Does not start agents.
param(
    [Parameter(Mandatory = $true)]
    [string]$Cwd,
    [string]$LayoutPath = (Join-Path $PSScriptRoot '..\layout.json'),
    [string]$WorkspaceLabel,
    [switch]$Rebuild
)

$ErrorActionPreference = 'Stop'
$herdr = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }
$Cwd = (Resolve-Path -LiteralPath $Cwd).Path
$LayoutPath = (Resolve-Path -LiteralPath $LayoutPath).Path
$layout = Get-Content -LiteralPath $LayoutPath -Raw -Encoding utf8 | ConvertFrom-Json
if (-not $WorkspaceLabel) { $WorkspaceLabel = $layout.workspace_label }
if (-not $WorkspaceLabel) { throw 'layout.json missing workspace_label' }

function Invoke-Herdr {
    $output = & $herdr @args
    $text = ($output | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { throw "herdr $($args -join ' ') failed ($LASTEXITCODE): $text" }
    try {
        $json = $text | ConvertFrom-Json
    }
    catch {
        throw "herdr $($args -join ' '): not JSON: $text"
    }
    if ($null -eq $json.result) { throw "herdr $($args -join ' '): no result: $text" }
    return $json.result
}

function Get-Workspaces { @( (Invoke-Herdr workspace list).workspaces ) }
function Get-Tabs([string]$WorkspaceId) {
    @((Invoke-Herdr tab list).tabs) | Where-Object { $_.workspace_id -eq $WorkspaceId }
}
function Get-Panes([string]$WorkspaceId, [string]$TabId) {
    @((Invoke-Herdr pane list --workspace $WorkspaceId).panes) | Where-Object { $_.tab_id -eq $TabId }
}

$status = & $herdr status 2>&1 | Out-String
if ($status -notmatch 'status:\s+running') { throw "Herdr server is not running.`n$status" }

$ws = Get-Workspaces | Where-Object { $_.label -eq $WorkspaceLabel } | Select-Object -First 1
$bootstrapTabId = $null
$bootstrapPaneId = $null
if (-not $ws) {
    $created = Invoke-Herdr workspace create --cwd $Cwd --label $WorkspaceLabel --no-focus
    $wsId = $created.workspace.workspace_id
    $bootstrapTabId = $created.tab.tab_id
    $bootstrapPaneId = $created.root_pane.pane_id
    $ws = Get-Workspaces | Where-Object { $_.workspace_id -eq $wsId } | Select-Object -First 1
}
$wsId = $ws.workspace_id

$paneMap = [ordered]@{}

foreach ($tabSpec in $layout.tabs) {
    $tabLabel = $tabSpec.label
    $tabs = @(Get-Tabs $wsId)
    $tab = $tabs | Where-Object { $_.label -eq $tabLabel } | Select-Object -First 1

    if ($Rebuild -and $tab -and ((Get-Tabs $wsId).Count -gt 1)) {
        Invoke-Herdr tab close $tab.tab_id | Out-Null
        $tab = $null
    }

    if ($bootstrapTabId) {
        Invoke-Herdr tab rename $bootstrapTabId $tabLabel | Out-Null
        $tabId = $bootstrapTabId
        $rootId = $bootstrapPaneId
        $bootstrapTabId = $null
        $bootstrapPaneId = $null
    }
    elseif (-not $tab) {
        $createdTab = Invoke-Herdr tab create --workspace $wsId --cwd $Cwd --label $tabLabel --no-focus
        $tabId = $createdTab.tab.tab_id
        $rootId = $createdTab.root_pane.pane_id
    }
    else {
        $tabId = $tab.tab_id
        $existing = @(Get-Panes $wsId $tabId)
        $rootId = $existing[0].pane_id
    }

    $ids = @($rootId)
    $paneSpecs = @($tabSpec.panes)
    for ($i = 1; $i -lt $paneSpecs.Count; $i++) {
        $have = @(Get-Panes $wsId $tabId)
        if ($have.Count -gt $i) {
            $ids += $have[$i].pane_id
            continue
        }
        $dir = $paneSpecs[$i].direction
        if (-not $dir) { $dir = 'right' }
        $split = Invoke-Herdr pane split $ids[-1] --direction $dir --cwd $Cwd --no-focus
        $newId = $split.pane.pane_id
        if (-not $newId) { $newId = $split.pane_id }
        $ids += $newId
    }

    for ($i = 0; $i -lt $paneSpecs.Count; $i++) {
        $label = $paneSpecs[$i].label
        Invoke-Herdr pane rename $ids[$i] $label | Out-Null
        $paneMap[$label] = $ids[$i]
    }
}

$result = [ordered]@{
    workspace_id    = $wsId
    workspace_label = $WorkspaceLabel
    cwd             = $Cwd
    panes           = $paneMap
}
$result | ConvertTo-Json -Compress
