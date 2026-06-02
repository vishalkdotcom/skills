param(
    [string]$Ticket,
    [ValidateSet('draft', 'final')]
    [string]$Mode = 'draft',
    [string[]]$Urls,
    [string]$UrlFile,
    [string[]]$ImageUrls,
    [string]$Filter,
    [string]$MonthDir,
    [string]$Context
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\_common.ps1"

$ctx = Get-TrpmGitHubContext -Override $Context
$blocks = @()

function New-VideoBlock {
    param([string]$SummaryTitle, [string]$Url)

    if ($Url) {
        return Format-TrpmDetailsBlock -SummaryTitle $SummaryTitle -BodyContent $Url
    }

    return Format-TrpmDetailsBlock -SummaryTitle $SummaryTitle -BodyContent '<!-- upload encoded file and paste URL -->'
}

function New-ImageBlock {
    param([string]$SummaryTitle, [string]$Url, [string]$Filename)

    $alt = [System.IO.Path]::GetFileNameWithoutExtension($Filename).ToLower()

    if ($Url) {
        $body = "<img width=`"2250`" height=`"3620`" alt=`"$alt`" src=`"$Url`" />"
        return Format-TrpmDetailsBlock -SummaryTitle $SummaryTitle -BodyContent $body
    }

    return Format-TrpmDetailsBlock -SummaryTitle $SummaryTitle -BodyContent "<!-- upload $Filename and paste URL -->"
}

if ($Mode -eq 'draft') {
    if (-not $Ticket) {
        throw '-Ticket is required for draft mode'
    }

    $assets = @(Get-TrpmTicketAssets -Ticket $Ticket -MonthDir $MonthDir)
    if ($Filter) {
        $assets = @($assets | Where-Object { $_.Name -like "*$Filter*" })
    }
    if (-not $assets.Count) {
        throw "No assets found for $Ticket$(if ($Filter) { " matching filter '$Filter'" })"
    }

    foreach ($asset in $assets) {
        if ($asset.Type -eq 'video') {
            $blocks += New-VideoBlock -SummaryTitle $asset.SummaryTitle -Url $null
        } else {
            $blocks += New-ImageBlock -SummaryTitle $asset.SummaryTitle -Url $null -Filename $asset.Name
        }
    }
} else {
    $urlList = @()
    if ($UrlFile) {
        $urlList = @(Get-Content -Path $UrlFile | Where-Object { $_.Trim() -ne '' })
    } elseif ($Urls) {
        $urlList = @($Urls)
    }

    if (-not $urlList.Count) {
        throw 'final mode requires -Urls or -UrlFile with video user-attachments URLs'
    }

    foreach ($url in $urlList) {
        $uploadName = Resolve-TrpmAssetFilename -Url $url -Context $ctx
        $summary = Get-TrpmTitleFromFilename -Filename $uploadName
        $blocks += New-VideoBlock -SummaryTitle $summary -Url $url
    }

    if ($ImageUrls -and $Ticket) {
        $images = @(Get-TrpmTicketAssets -Ticket $Ticket -MonthDir $MonthDir | Where-Object { $_.Type -eq 'image' })
        for ($i = 0; $i -lt $ImageUrls.Count; $i++) {
            $img = $images[$i]
            if (-not $img) { break }
            $blocks += New-ImageBlock -SummaryTitle $img.SummaryTitle -Url $ImageUrls[$i] -Filename $img.Name
        }
    } elseif ($ImageUrls -and -not $Ticket) {
        throw 'Pass -Ticket with -ImageUrls so image summary titles come from ShareX filenames'
    }
}

Write-Output ($blocks -join "`n`n")
