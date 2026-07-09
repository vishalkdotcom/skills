# Link %USERPROFILE%\.agents\skills -> this repo's skills\ tree (native NTFS junction).
# Run in Windows PowerShell / pwsh (not WSL), from anywhere:
#   pwsh -File C:\Users\vishal\repos\skills\scripts\setup-windows-agents-link.ps1
#
# Or clone + link in one shot (see README / comment at bottom of this file).
$ErrorActionPreference = 'Stop'

$RepoSkills = (Resolve-Path (Join-Path $PSScriptRoot '..\skills')).Path
$AgentsDir = Join-Path $env:USERPROFILE '.agents'
$SkillsLink = Join-Path $AgentsDir 'skills'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmm'

if (-not (Test-Path (Join-Path $RepoSkills 'grilling\SKILL.md'))) {
    throw "Expected skill tree missing at $RepoSkills"
}

New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null

if (Test-Path $SkillsLink) {
    $item = Get-Item $SkillsLink -Force
    $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    if ($isReparse) {
        Write-Host "Removing existing link: $SkillsLink"
        cmd /c "rmdir `"$SkillsLink`""
        if ($LASTEXITCODE -ne 0) { throw "rmdir failed with exit $LASTEXITCODE" }
    }
    else {
        $bak = "$SkillsLink.bak.$Stamp"
        Write-Host "Backing up existing folder -> $bak"
        Rename-Item -LiteralPath $SkillsLink -NewName (Split-Path $bak -Leaf)
    }
}

Write-Host "Creating junction:`n  $SkillsLink`n  => $RepoSkills"
cmd /c "mklink /J `"$SkillsLink`" `"$RepoSkills`""
if ($LASTEXITCODE -ne 0) { throw "mklink failed with exit $LASTEXITCODE" }

$probe = Join-Path $SkillsLink 'wayfinder\SKILL.md'
if (-not (Test-Path $probe)) { throw "Link created but probe failed: $probe" }
Write-Host "OK: $probe"
Get-Item $SkillsLink | Format-List FullName, Attributes, LinkType, Target
