function Get-PlaywrightResult {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RawOutput
  )

  $text = $RawOutput.Trim()
  if ($text -match '### Result\s+(.+?)(?:\r?\n)### Ran Playwright code') {
    return $Matches[1].Trim().Trim('"')
  }
  if ($text -match '### Result\s+(\S+)') {
    return $Matches[1].Trim().Trim('"')
  }
  throw "Could not parse Playwright CLI result from: $text"
}
