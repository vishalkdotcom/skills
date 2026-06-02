param(
    [Parameter(Mandatory)][string]$Url,
    [string]$Context
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_common.ps1"

$ctx = Get-TrpmGitHubContext -Override $Context
$name = Resolve-TrpmAssetFilename -Url $Url -Context $ctx
Write-Output $name
