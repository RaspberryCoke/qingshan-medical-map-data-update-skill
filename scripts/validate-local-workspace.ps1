param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$csvPath = '_local/input/medical-feedback.csv'
$jsonFiles = @(
  'src/_data/medicalData.json',
  'src/_data/medicalChildData.json',
  'src/_data/medicalAbroadData.json'
)
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

function ConvertFrom-Utf8Base64 {
  param([Parameter(Mandatory = $true)][string]$Value)

  return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

$requiredHeaders = $requiredHeaderBase64 | ForEach-Object { ConvertFrom-Utf8Base64 -Value $_ }

function Assert-Exists {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Message
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    throw $Message
  }
}

function Assert-CsvHeader {
  param([Parameter(Mandatory = $true)][string]$Path)

  $header = Get-Content -LiteralPath $Path -Encoding UTF8 -TotalCount 1
  if ([string]::IsNullOrWhiteSpace($header)) {
    throw 'CSV header is empty.'
  }

  foreach ($requiredHeader in $requiredHeaders) {
    if ($header -notlike "*$requiredHeader*") {
      throw "CSV header is missing required column: $requiredHeader"
    }
  }
}

Assert-Exists -Path '.git' -Message 'Current directory is not the cloned target repository root: missing .git/.'
foreach ($jsonFile in $jsonFiles) {
  Assert-Exists -Path $jsonFile -Message "Missing target JSON: $jsonFile"
}

Assert-Exists -Path $csvPath -Message "Missing CSV: $csvPath"
$csvLines = (Get-Content -LiteralPath $csvPath -Encoding UTF8 | Measure-Object -Line).Lines
if ($csvLines -lt 1) {
  throw "CSV is empty: $csvPath"
}
Assert-CsvHeader -Path $csvPath

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw 'Node.js is required for JSON parse validation.'
}

foreach ($jsonFile in $jsonFiles) {
  node -e "const text = require('fs').readFileSync(process.argv[1], 'utf8').replace(/^\uFEFF/, ''); JSON.parse(text); console.log(process.argv[1] + ' OK');" $jsonFile
  if ($LASTEXITCODE -ne 0) {
    throw "JSON parse failed: $jsonFile"
  }
}

git status --short --branch

Write-Host ''
Write-Host 'Validation complete.'
Write-Host 'Before committing target repository changes, confirm these are not staged or committed:'
Write-Host '- _local/'
Write-Host '- .codex/'
Write-Host '- CSV / TSV'
Write-Host '- logs'
Write-Host '- .env'
Write-Host '- credentials'
Write-Host '- package files'
Write-Host '- lockfiles'
Write-Host '- git hooks'
Write-Host '- pnpm-workspace.yaml'
