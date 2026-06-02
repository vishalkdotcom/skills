param(
    [Parameter(Mandatory)][string]$Ticket,
    [string]$MonthDir,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_common.ps1"

$assets = @(Get-TrpmTicketAssets -Ticket $Ticket -MonthDir $MonthDir)
$context = Get-TrpmGitHubContext

if ($Json) {
    $assets | Select-Object Name, FullPath, Type, SummaryTitle, EncodedName, EncodedPath, EncodedExists, Source |
        ConvertTo-Json -Depth 3
    exit 0
}

Write-Host "Ticket:     $Ticket"
Write-Host "GitHub ctx: $context"
Write-Host "Month dir:  $(if ($MonthDir) { $MonthDir } else { Get-TrpmLatestMonthDir -ShareXDir (Get-TrpmShareXDir) })"
Write-Host ''

if ($assets.Count -eq 0) {
    Write-Host "No assets found for $Ticket"
    exit 1
}

$assets | Format-Table Name, Type, SummaryTitle, EncodedExists, @{ N = 'SizeMB'; E = { [math]::Round((Get-Item $_.FullPath).Length / 1MB, 1) } } -AutoSize
