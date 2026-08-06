# Selectively junction skills from this repo into %USERPROFILE%\.agents\skills.
# Creates a real directory of per-skill NTFS junctions (not a whole-tree link),
# skipping names listed in .agents-runtime-exclude.
#
# Run in Windows PowerShell / pwsh (not WSL), from anywhere:
#   pwsh -File C:\Users\vishal\repos\skills\scripts\setup-windows-agents-link.ps1
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RepoSkills = Join-Path $RepoRoot 'skills'
$ExcludeFile = Join-Path $RepoRoot '.agents-runtime-exclude'
$AgentsDir = Join-Path $env:USERPROFILE '.agents'
$SkillsLink = Join-Path $AgentsDir 'skills'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmm'

if (-not (Test-Path (Join-Path $RepoSkills 'grilling\SKILL.md'))) {
    throw "Expected skill tree missing at $RepoSkills"
}

$excluded = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
if (Test-Path $ExcludeFile) {
    Get-Content $ExcludeFile | ForEach-Object {
        $line = ($_ -replace '#.*$', '').Trim()
        if ($line) { [void]$excluded.Add($line) }
    }
}

$wanted = Get-ChildItem $RepoSkills -Directory |
    Where-Object { -not $excluded.Contains($_.Name) -and (Test-Path (Join-Path $_.FullName 'SKILL.md')) } |
    Select-Object -ExpandProperty Name |
    Sort-Object

if ($wanted.Count -eq 0) { throw 'No skills to link (check .agents-runtime-exclude).' }

New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null

if (Test-Path $SkillsLink) {
    $item = Get-Item $SkillsLink -Force
    $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    if ($isReparse) {
        Write-Host "Removing existing whole-tree link: $SkillsLink"
        cmd /c "rmdir `"$SkillsLink`""
        if ($LASTEXITCODE -ne 0) { throw "rmdir failed with exit $LASTEXITCODE" }
    }
    else {
        $bak = "$SkillsLink.bak.$Stamp"
        Write-Host "Backing up existing folder -> $bak"
        Rename-Item -LiteralPath $SkillsLink -NewName (Split-Path $bak -Leaf)
    }
}

New-Item -ItemType Directory -Force -Path $SkillsLink | Out-Null

$linked = 0
foreach ($name in $wanted) {
    $src = Join-Path $RepoSkills $name
    $dest = Join-Path $SkillsLink $name
    if (Test-Path $dest) {
        $destItem = Get-Item $dest -Force
        if ([bool]($destItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            cmd /c "rmdir `"$dest`"" | Out-Null
        }
        else {
            throw "Refusing to overwrite non-junction path: $dest"
        }
    }
    cmd /c "mklink /J `"$dest`" `"$src`"" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "mklink failed for $name (exit $LASTEXITCODE)" }
    $linked++
}

$skipped = @($excluded)
Write-Host "Linked $linked skills into $SkillsLink"
if ($skipped.Count -gt 0) {
    Write-Host "Excluded ($($skipped.Count)): $($skipped -join ', ')"
}

$probe = Join-Path $SkillsLink 'wayfinder\SKILL.md'
if (-not (Test-Path $probe)) { throw "Link created but probe failed: $probe" }
Write-Host "OK: $probe"
Get-ChildItem $SkillsLink -Directory | Select-Object -ExpandProperty Name | Sort-Object
