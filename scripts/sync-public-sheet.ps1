param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$Url,

  [string]$OutputPath = (Join-Path $PSScriptRoot '..\input\medical-feedback.csv'),

  [string]$LogPath = (Join-Path $PSScriptRoot '..\logs\sync-public-sheet.log')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredHeaderBase64 = @(
  '5bqP5Y+3',
  '5pu05paw54q25oCB',
  '5YiG57G7',
  '55yB5Lu9L+WfjuW4gg==',
  '5Yy76Zmi5ZCN56ew',
  '5Yy755Sf5aeT5ZCN',
  '6K+K55aX5pa55ZCR',
  '5bCx6K+K6K+E5Lu35LiO6K+m57uG5pu05paw5L+h5oGv',
  '6ZO+5o6l'
)
$requiredJsonFiles = @(
  'src/_data/medicalData.json',
  'src/_data/medicalChildData.json',
  'src/_data/medicalAbroadData.json'
)

function ConvertFrom-Utf8Base64 {
  param([Parameter(Mandatory = $true)][string]$Value)

  return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

$requiredHeaders = $requiredHeaderBase64 | ForEach-Object { ConvertFrom-Utf8Base64 -Value $_ }

function Write-SyncLog {
  param([Parameter(Mandatory = $true)][string]$Message)

  $logDirectory = Split-Path -Parent $LogPath
  if (-not (Test-Path -LiteralPath $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
  }

  Add-Content -LiteralPath $LogPath -Encoding UTF8 -Value $Message
}

function Assert-TargetRepoRoot {
  if (-not (Test-Path -LiteralPath '.git')) {
    throw 'Current directory is not the cloned target repository root: missing .git/.'
  }

  foreach ($file in $requiredJsonFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
      throw "Current directory is not the expected target repository root: missing $file."
    }
  }
}

function Assert-CsvHeader {
  param([Parameter(Mandatory = $true)][string]$Path)

  $header = Get-Content -LiteralPath $Path -Encoding UTF8 -TotalCount 1
  if ([string]::IsNullOrWhiteSpace($header)) {
    throw 'Downloaded CSV header is empty.'
  }

  foreach ($requiredHeader in $requiredHeaders) {
    if ($header -notlike "*$requiredHeader*") {
      throw "Downloaded CSV header is missing required column: $requiredHeader"
    }
  }
}

$startedAt = (Get-Date).ToString('o')
$outputDirectory = Split-Path -Parent $OutputPath
$temporaryPath = "$OutputPath.tmp"

try {
  Assert-TargetRepoRoot

  if ($Url -notmatch '^https://') {
    throw 'The published CSV URL must use https://.'
  }

  if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  }

  Invoke-WebRequest -Uri $Url -OutFile $temporaryPath -UseBasicParsing

  if (-not (Test-Path -LiteralPath $temporaryPath)) {
    throw 'Download finished but the temporary CSV file was not created.'
  }

  $lineCount = (Get-Content -LiteralPath $temporaryPath -Encoding UTF8 | Measure-Object -Line).Lines
  if ($lineCount -lt 1) {
    throw 'Downloaded CSV is empty.'
  }

  Assert-CsvHeader -Path $temporaryPath
  Move-Item -LiteralPath $temporaryPath -Destination $OutputPath -Force

  $entry = @(
    "[$startedAt]"
    'url: (provided at runtime, not logged)'
    "output: $OutputPath"
    "lines: $lineCount"
    'success: yes'
    ''
  ) -join [Environment]::NewLine
  Write-SyncLog -Message $entry

  Write-Host 'Downloaded public CSV.'
  Write-Host "Output: $OutputPath"
  Write-Host "Lines: $lineCount"
  Write-Host "Log: $LogPath"
} catch {
  $message = $_.Exception.Message
  $entry = @(
    "[$startedAt]"
    'url: (provided at runtime, not logged)'
    "output: $OutputPath"
    'success: no'
    "error: $message"
    ''
  ) -join [Environment]::NewLine
  Write-SyncLog -Message $entry

  if (Test-Path -LiteralPath $temporaryPath) {
    Remove-Item -LiteralPath $temporaryPath -Force
  }

  throw
}
