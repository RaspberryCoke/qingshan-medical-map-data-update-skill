param(
  [string]$TaskSlug = "update-medical-map-data-$(Get-Date -Format yyyyMMdd)",
  [string]$ExpectedOrigin = 'ittuann/qingshanasd',
  [string]$SkillRoot = '',
  [string]$PublishedCsvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vRxiGx8JadZ-HPRJBb8-PMscizOv-4UpMqa56XZOhvr8ddkS99vm7hFJ-yee7c3btGrR4eXPRW_SAdi/pub?gid=1596563937&single=true&output=csv',
  [switch]$SkipSkillUpdate,
  [switch]$SkipCsvSync
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredJsonFiles = @(
  'src/_data/medicalData.json',
  'src/_data/medicalChildData.json',
  'src/_data/medicalAbroadData.json'
)
$proxyVariables = @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'http_proxy', 'https_proxy', 'all_proxy')

function Assert-Command {
  param([Parameter(Mandatory = $true)][string]$Name)

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $Name"
  }
}

function Get-ProxySnapshot {
  $snapshot = @{}
  foreach ($name in $proxyVariables) {
    $snapshot[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
  }
  return $snapshot
}

function Restore-ProxySnapshot {
  param([Parameter(Mandatory = $true)][hashtable]$Snapshot)

  foreach ($name in $proxyVariables) {
    [Environment]::SetEnvironmentVariable($name, $Snapshot[$name], 'Process')
  }
}

function Clear-ProxyEnvironment {
  foreach ($name in $proxyVariables) {
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
  }
}

function Set-LocalProxyEnvironment {
  [Environment]::SetEnvironmentVariable('HTTP_PROXY', 'http://127.0.0.1:7890', 'Process')
  [Environment]::SetEnvironmentVariable('HTTPS_PROXY', 'http://127.0.0.1:7890', 'Process')
}

function Test-LocalProxy {
  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $async = $client.BeginConnect('127.0.0.1', 7890, $null, $null)
    if (-not $async.AsyncWaitHandle.WaitOne(1000, $false)) {
      return $false
    }
    $client.EndConnect($async)
    return $true
  } catch {
    return $false
  } finally {
    $client.Close()
  }
}

function Invoke-External {
  param(
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  & $Command @Arguments | ForEach-Object { Write-Host $_ }
  return $LASTEXITCODE
}

function Invoke-GitHubCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$Description
  )

  Write-Host "Running: $Description"
  $snapshot = Get-ProxySnapshot
  $hadProxy = $proxyVariables | Where-Object { -not [string]::IsNullOrWhiteSpace($snapshot[$_]) } | Select-Object -First 1

  try {
    $exitCode = Invoke-External -Command $Command -Arguments $Arguments
    if ($exitCode -eq 0) {
      return
    }

    if ($hadProxy) {
      Write-Warning "$Description failed while proxy variables were set. Retrying once without proxy."
      Clear-ProxyEnvironment
      $exitCode = Invoke-External -Command $Command -Arguments $Arguments
      if ($exitCode -eq 0) {
        return
      }
    }

    if (Test-LocalProxy) {
      Write-Warning "$Description failed. Retrying once with HTTP(S)_PROXY=http://127.0.0.1:7890."
      Set-LocalProxyEnvironment
      $exitCode = Invoke-External -Command $Command -Arguments $Arguments
      if ($exitCode -eq 0) {
        return
      }
    }

    throw "$Description failed after direct/proxy recovery attempts."
  } finally {
    Restore-ProxySnapshot -Snapshot $snapshot
  }
}

function Resolve-SkillRoot {
  if (-not [string]::IsNullOrWhiteSpace($SkillRoot)) {
    return $SkillRoot
  }

  $marker = '_local/workflow/skill-root.txt'
  if (Test-Path -LiteralPath $marker) {
    $value = (Get-Content -LiteralPath $marker -Encoding UTF8 -TotalCount 1).Trim()
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      return $value
    }
  }

  return ''
}

function Update-SkillIfNeeded {
  if ($SkipSkillUpdate) {
    Write-Host 'Skipping skill self-update check.'
    return
  }

  $resolvedSkillRoot = Resolve-SkillRoot
  if ([string]::IsNullOrWhiteSpace($resolvedSkillRoot)) {
    Write-Warning 'Skill root is unknown; skipping automatic skill update check.'
    return
  }

  $updaterScript = Join-Path $PSScriptRoot 'update-installed-skill.ps1'
  if (-not (Test-Path -LiteralPath $updaterScript)) {
    $updaterScript = Join-Path $resolvedSkillRoot 'scripts/update-installed-skill.ps1'
  }
  if (Test-Path -LiteralPath $updaterScript) {
    & $updaterScript -InstalledSkillRoot $resolvedSkillRoot
  } else {
    Write-Warning 'Installed skill updater script is unavailable; falling back to Git repository update check.'
  }

  if (-not (Test-Path -LiteralPath (Join-Path $resolvedSkillRoot '.git'))) {
    Write-Host "Installed skill version check passed. Skill root is not a Git repository: $resolvedSkillRoot"
    return
  }

  $dirty = git -C $resolvedSkillRoot status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect skill repository status.'
  }
  if ($dirty) {
    throw "Skill repository has local changes; stop before running the workflow: $resolvedSkillRoot"
  }

  $upstream = git -C $resolvedSkillRoot rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($upstream)) {
    Write-Warning "Skill repository has no upstream branch; skipping automatic skill update: $resolvedSkillRoot"
    return
  }

  Invoke-GitHubCommand -Command git -Arguments @('-C', $resolvedSkillRoot, 'fetch', 'origin') -Description 'fetch latest skill repository state'
  $behind = git -C $resolvedSkillRoot rev-list --count 'HEAD..@{u}'
  if ($LASTEXITCODE -ne 0) {
    throw 'Could not compare skill repository with upstream.'
  }

  if ([int]$behind -gt 0) {
    Invoke-GitHubCommand -Command git -Arguments @('-C', $resolvedSkillRoot, 'pull', '--ff-only') -Description 'fast-forward update skill repository'
    throw 'The skill repository was updated. Restart Codex or start a new run so the updated skill instructions are loaded.'
  }

  Write-Host 'Skill repository is up to date.'
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

function Assert-CleanWorktree {
  $status = git status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect target repository status.'
  }
  if ($status) {
    throw 'Target repository has local changes. Commit, stash, or discard them before preflight switches branches.'
  }
}

function Assert-Origin {
  $origin = git remote get-url origin
  if ($LASTEXITCODE -ne 0) {
    throw 'Could not read origin remote.'
  }
  if ($origin -notmatch [regex]::Escape($ExpectedOrigin)) {
    throw "Unexpected origin remote. Expected it to contain '$ExpectedOrigin', got '$origin'."
  }
}

function Normalize-TaskSlug {
  param([Parameter(Mandatory = $true)][string]$Value)

  $slug = $Value.ToLowerInvariant() -replace '[^a-z0-9._-]+', '-'
  $slug = $slug.Trim('-')
  if ([string]::IsNullOrWhiteSpace($slug)) {
    throw 'Task slug cannot be empty after normalization.'
  }
  return $slug
}

function Initialize-LocalWorkspace {
  @(
    '_local/input',
    '_local/scripts',
    '_local/logs',
    '_local/workflow'
  ) | ForEach-Object {
    New-Item -ItemType Directory -Path $_ -Force | Out-Null
  }

  $resolvedSkillRoot = Resolve-SkillRoot
  if (-not [string]::IsNullOrWhiteSpace($resolvedSkillRoot) -and (Test-Path -LiteralPath $resolvedSkillRoot)) {
    Set-Content -LiteralPath '_local/workflow/skill-root.txt' -Encoding UTF8 -Value $resolvedSkillRoot
  }
}

function Sync-CsvIfNeeded {
  if ($SkipCsvSync) {
    Write-Host 'Skipping CSV sync.'
    return
  }

  $csvPath = '_local/input/medical-feedback.csv'
  if (Test-Path -LiteralPath $csvPath) {
    Write-Host "CSV already exists: $csvPath"
    return
  }

  $syncScript = '_local/scripts/sync-public-sheet.ps1'
  if (-not (Test-Path -LiteralPath $syncScript)) {
    Write-Warning "CSV is missing and sync script is unavailable: $syncScript"
    return
  }

  & $syncScript -Url $PublishedCsvUrl
  if ($LASTEXITCODE -ne 0) {
    throw 'CSV sync failed.'
  }
}

Update-SkillIfNeeded
Assert-Command -Name git
Assert-Command -Name gh
Assert-Command -Name node

Assert-TargetRepoRoot
Assert-Origin
Assert-CleanWorktree

git --version
gh --version
node --version
Invoke-GitHubCommand -Command gh -Arguments @('auth', 'status') -Description 'check GitHub CLI authentication'

Initialize-LocalWorkspace
Sync-CsvIfNeeded

Invoke-External -Command git -Arguments @('switch', 'main') | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw 'Could not switch to main.'
}
Invoke-GitHubCommand -Command git -Arguments @('pull', '--ff-only', 'origin', 'main') -Description 'fast-forward target repository main'

$branchName = "codex/$(Normalize-TaskSlug -Value $TaskSlug)"
$existingBranch = git branch --list $branchName
if ($existingBranch) {
  git switch $branchName
} else {
  git switch -c $branchName
}
if ($LASTEXITCODE -ne 0) {
  throw "Could not switch to task branch: $branchName"
}

Write-Host ''
Write-Host 'Preflight complete.'
Write-Host "Task branch: $branchName"
Write-Host 'Continue with read-only CSV/JSON analysis before any approved JSON edits.'
