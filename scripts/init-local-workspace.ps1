param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredJsonFiles = @(
  'src/_data/medicalData.json',
  'src/_data/medicalChildData.json',
  'src/_data/medicalAbroadData.json'
)

function Resolve-SkillRoot {
  return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
}

function Assert-TargetRepoRoot {
  if (-not (Test-Path -LiteralPath '.git')) {
    throw 'Current directory is not the cloned target repository root: missing .git/. Run this script after git clone and cd <target-repo>.'
  }

  foreach ($file in $requiredJsonFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
      throw "Current directory is not the expected target repository root: missing $file."
    }
  }
}

function Copy-RequiredFile {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source)) {
    throw "Required skill file was not found: $Source"
  }

  $destinationDirectory = Split-Path -Parent $Destination
  if (-not (Test-Path -LiteralPath $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
  }

  Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

Assert-TargetRepoRoot

$skillRoot = Resolve-SkillRoot

@(
  '_local/input',
  '_local/scripts',
  '_local/logs',
  '_local/workflow'
) | ForEach-Object {
  New-Item -ItemType Directory -Path $_ -Force | Out-Null
}

Copy-RequiredFile -Source (Join-Path $skillRoot 'scripts/sync-public-sheet.ps1') -Destination '_local/scripts/sync-public-sheet.ps1'
Copy-RequiredFile -Source (Join-Path $skillRoot 'scripts/validate-local-workspace.ps1') -Destination '_local/scripts/validate-local-workspace.ps1'
Copy-RequiredFile -Source (Join-Path $skillRoot 'scripts/preflight-medical-workflow.ps1') -Destination '_local/scripts/preflight-medical-workflow.ps1'
Copy-RequiredFile -Source (Join-Path $skillRoot 'templates/medical-data-workflow.md') -Destination '_local/workflow/medical-data-workflow.md'
Copy-RequiredFile -Source (Join-Path $skillRoot 'templates/RUNBOOK.md') -Destination '_local/workflow/RUNBOOK.md'
Copy-RequiredFile -Source (Join-Path $skillRoot 'templates/medical-workflow-lessons.md') -Destination '_local/workflow/medical-workflow-lessons.md'
Set-Content -LiteralPath '_local/workflow/skill-root.txt' -Encoding UTF8 -Value $skillRoot

$gitignoreMissing = $true
if (Test-Path -LiteralPath '.gitignore') {
  $gitignoreMissing = -not (Select-String -LiteralPath '.gitignore' -Pattern '^\s*/_local/\s*$' -Quiet)
}

Write-Host 'Local medical map workspace initialized.'
Write-Host 'Created or verified: _local/input, _local/scripts, _local/logs, _local/workflow'
Write-Host 'Copied Windows workflow scripts, preflight, and templates.'

if ($gitignoreMissing) {
  Write-Warning 'The target repository .gitignore does not appear to ignore /_local/. Add this line manually if needed: /_local/'
}

Write-Host 'Do not commit _local/, CSV exports, logs, credentials, or local workflow scratch files to the target repository.'
