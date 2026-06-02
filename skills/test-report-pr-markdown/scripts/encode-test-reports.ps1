param(
    [Parameter(Mandatory)][string]$Ticket,
    [string]$MonthDir,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_common.ps1"

$cli = Get-Command handbrakecli.exe -ErrorAction SilentlyContinue
if (-not $cli) {
    throw 'handbrakecli.exe not found on PATH (install handbrake-cli via scoop)'
}

$preset = Get-TrpmHandbrakePreset
# @() required: a single pipeline object has no .Count in Windows PowerShell
$assets = @(Get-TrpmTicketAssets -Ticket $Ticket -MonthDir $MonthDir |
    Where-Object { $_.Type -eq 'video' -and $_.Source -eq 'sharex' })

if ($assets.Count -eq 0) {
    Write-Host "No ShareX videos to encode for $Ticket"
    exit 0
}

foreach ($asset in $assets) {
    $inputPath = $asset.FullPath
    $outputPath = $asset.EncodedPath

    if ((Test-Path $outputPath) -and -not $Force) {
        $outTime = (Get-Item $outputPath).LastWriteTime
        $inTime = (Get-Item $inputPath).LastWriteTime
        if ($outTime -ge $inTime) {
            Write-Host "Skip (up to date): $($asset.EncodedName)"
            continue
        }
    }

    Write-Host "Encoding: $($asset.Name) -> $($asset.EncodedName)"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & handbrakecli.exe -i $inputPath -o $outputPath -Z $preset *> $null
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($exitCode -ne 0) {
        throw "HandBrakeCLI failed for $($asset.Name) (exit $exitCode)"
    }
    $sw.Stop()

    $sizeMb = [math]::Round((Get-Item $outputPath).Length / 1MB, 1)
    Write-Host "Done in $([math]::Round($sw.Elapsed.TotalSeconds, 1))s -> ${sizeMb}MB"
}
