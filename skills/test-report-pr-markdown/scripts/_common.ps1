# Shared helpers for test-report-pr-markdown scripts.

function Get-TrpmShareXDir {
    if ($env:TRPM_SHAREX_DIR) { return $env:TRPM_SHAREX_DIR }
    return 'C:\Users\vishal\scoop\apps\sharex\current\ShareX\Screenshots'
}

function Get-TrpmVideosDir {
    if ($env:TRPM_VIDEOS_DIR) { return $env:TRPM_VIDEOS_DIR }
    return 'C:\Users\vishal\Videos'
}

function Get-TrpmHandbrakePreset {
    if ($env:TRPM_HANDBRAKE_PRESET) { return $env:TRPM_HANDBRAKE_PRESET }
    return 'Very Fast 1080p30'
}

function Get-TrpmGitHubContext {
    param(
        [string]$Override,
        [string]$Fallback = 'laborsolutions/wovo_frontend'
    )

    if ($Override) { return $Override }
    if ($env:TRPM_GITHUB_CONTEXT) { return $env:TRPM_GITHUB_CONTEXT }

    $remote = $null
    try {
        $remote = git remote get-url origin 2>$null
    } catch {
        $remote = $null
    }

    if ($remote -match 'github\.com[:/\\]+([^/\\]+)/([^/.]+?)(?:\.git)?$') {
        return "$($Matches[1])/$($Matches[2])"
    }

    return $Fallback
}

function Get-TrpmTitleFromFilename {
    param([Parameter(Mandatory)][string]$Filename)

    $base = [System.IO.Path]::GetFileNameWithoutExtension($Filename)
    $slug = $null

    if ($base -match '^wpm-\d+-test-report-(.+)$') {
        $slug = $Matches[1]
    } elseif ($base -match '^wpm-\d+-(.+)$') {
        $slug = $Matches[1]
    } else {
        $slug = $base
    }

    $words = $slug -split '-' | Where-Object { $_ -ne '' }
    $titleWords = foreach ($word in $words) {
        (Get-Culture).TextInfo.ToTitleCase($word.ToLower())
    }

    return "Test Report - $($titleWords -join ' ')"
}

function Get-TrpmEncodedBasename {
    param([Parameter(Mandatory)][string]$Filename)

    $base = [System.IO.Path]::GetFileNameWithoutExtension($Filename)
    return (Get-Culture).TextInfo.ToTitleCase($base.Replace('_', '-'))
}

function Get-TrpmLatestMonthDir {
    param([Parameter(Mandatory)][string]$ShareXDir)

    $months = Get-ChildItem -Path $ShareXDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{4}-\d{2}$' } |
        Sort-Object Name -Descending

    if (-not $months) {
        throw "No YYYY-MM folders under $ShareXDir"
    }

    return $months[0].FullName
}

function Get-TrpmTicketPattern {
    param([Parameter(Mandatory)][string]$Ticket)

    $normalized = $Ticket.ToLower()
    if ($normalized -notmatch '^wpm-\d+$') {
        throw "Ticket must look like wpm-3267 (got: $Ticket)"
    }

    return "$normalized*"
}

function Get-TrpmTicketAssets {
    param(
        [Parameter(Mandatory)][string]$Ticket,
        [string]$MonthDir
    )

    $shareXDir = Get-TrpmShareXDir
    $videosDir = Get-TrpmVideosDir
    $pattern = Get-TrpmTicketPattern -Ticket $Ticket

    if (-not $MonthDir) {
        $MonthDir = Get-TrpmLatestMonthDir -ShareXDir $shareXDir
    }

    $shareXFiles = @(Get-ChildItem -Path $MonthDir -File -Filter $pattern -ErrorAction SilentlyContinue)
    $encodedFiles = @(Get-ChildItem -Path $videosDir -File -Filter $pattern -ErrorAction SilentlyContinue)

    $items = @()

    foreach ($file in $shareXFiles) {
        $encodedName = "$(Get-TrpmEncodedBasename -Filename $file.Name).$($file.Extension.TrimStart('.'))"
        $encodedPath = Join-Path $videosDir $encodedName
        $encodedItem = $encodedFiles | Where-Object { $_.Name -ieq $encodedName } | Select-Object -First 1

        $items += [pscustomobject]@{
            Name          = $file.Name
            FullPath      = $file.FullName
            Extension     = $file.Extension.ToLower()
            Type          = if ($file.Extension -match '^\.(mp4|webm|mov)$') { 'video' } else { 'image' }
            SummaryTitle  = Get-TrpmTitleFromFilename -Filename $file.Name
            EncodedName   = $encodedName
            EncodedPath   = if ($encodedItem) { $encodedItem.FullName } else { $encodedPath }
            EncodedExists = [bool]$encodedItem
            Source        = 'sharex'
        }
    }

    foreach ($file in $encodedFiles) {
        $already = $items | Where-Object { $_.EncodedName -ieq $file.Name }
        if ($already) { continue }

        $items += [pscustomobject]@{
            Name          = $file.Name
            FullPath      = $file.FullName
            Extension     = $file.Extension.ToLower()
            Type          = if ($file.Extension -match '^\.(mp4|webm|mov)$') { 'video' } else { 'image' }
            SummaryTitle  = Get-TrpmTitleFromFilename -Filename $file.Name
            EncodedName   = $file.Name
            EncodedPath   = $file.FullName
            EncodedExists = $true
            Source        = 'videos'
        }
    }

    return Sort-TrpmAssets -Items $items
}

function Sort-TrpmAssets {
    param([array]$Items)

    return $Items | Sort-Object {
        $n = $_.Name.ToLower()
        $rank = 5
        if ($n -match 'before') { $rank = 1 }
        elseif ($n -match 'prod') { $rank = 3 }
        elseif ($n -match 'after') { $rank = 2 }
        elseif ($n -match 'unit-test') { $rank = 9 }
        '{0:D2}-{1}' -f $rank, $_.Name
    }
}

function Resolve-TrpmAssetFilename {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$Context
    )

    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        throw 'gh CLI required to resolve asset URLs (install and run gh auth login)'
    }

    # Prefer gh api over Invoke-RestMethod + token (same HTML, fewer auth edge cases)
    $response = gh api markdown -X POST -f "text=$Url" -f mode=gfm -f "context=$Context" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "gh api markdown failed for asset URL: $Url`n$response"
    }
    $response = [string]$response

    if ($response -match '<span class="m-1">([^<]+\.(mp4|webm|mov|png|jpe?g|gif))</span>') {
        return $Matches[1]
    }

    throw "Could not resolve filename from URL (not a video attachment?): $Url"
}

function Format-TrpmDetailsBlock {
    param(
        [Parameter(Mandatory)][string]$SummaryTitle,
        [Parameter(Mandatory)][string]$BodyContent,
        [string]$Alt
    )

    $lines = @(
        '<details>'
        "<summary><b>$SummaryTitle</b></summary>"
        ''
        $BodyContent
        '</details>'
    )

    return ($lines -join "`n")
}
