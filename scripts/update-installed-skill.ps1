param(
  [string]$InstalledSkillRoot = (Join-Path $HOME '.codex\skills\qingshan-medical-map-data-update-skill'),
  [string]$RepoUrl = 'https://github.com/RaspberryCoke/qingshan-medical-map-data-update-skill.git',
  [string]$Branch = 'main',
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$skillName = 'qingshan-medical-map-data-update-skill'
$versionFile = '.codex-skill-version.json'
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

function Read-SkillVersion {
  param([Parameter(Mandatory = $true)][string]$Root)

  $path = Join-Path $Root $versionFile
  if (-not (Test-Path -LiteralPath $path)) {
    return ''
  }
  $metadata = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
  return [string]$metadata.version
}

function Assert-InstallDestination {
  param([Parameter(Mandatory = $true)][string]$Path)

  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $expectedParent = [System.IO.Path]::GetFullPath((Join-Path $HOME '.codex\skills'))
  $expectedPath = [System.IO.Path]::GetFullPath((Join-Path $expectedParent $skillName))

  if ($fullPath -ne $expectedPath) {
    throw "Refusing to reinstall unexpected skill path: $fullPath"
  }
  if (-not $fullPath.StartsWith($expectedParent, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to reinstall path outside Codex skills directory: $fullPath"
  }

  return $fullPath
}

function Install-TrackedFiles {
  param(
    [Parameter(Mandatory = $true)][string]$SourceRoot,
    [Parameter(Mandatory = $true)][string]$DestinationRoot
  )

  if (Test-Path -LiteralPath $DestinationRoot) {
    Remove-Item -LiteralPath $DestinationRoot -Recurse -Force
  }
  New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null

  $trackedFiles = git -C $SourceRoot ls-files
  if ($LASTEXITCODE -ne 0) {
    throw 'Could not list tracked skill files from cloned repository.'
  }

  foreach ($relative in $trackedFiles) {
    $relativePath = $relative -replace '/', [System.IO.Path]::DirectorySeparatorChar
    $source = Join-Path $SourceRoot $relativePath
    $destination = Join-Path $DestinationRoot $relativePath
    $destinationDirectory = Split-Path -Parent $destination
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
      New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $destination -Force
  }

  return $trackedFiles.Count
}

Assert-Command -Name git

$installedRoot = Assert-InstallDestination -Path $InstalledSkillRoot
$currentVersion = Read-SkillVersion -Root $installedRoot
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("$skillName-update-" + [guid]::NewGuid().ToString('N'))

try {
  Invoke-GitHubCommand -Command git -Arguments @('clone', '--depth', '1', '--branch', $Branch, $RepoUrl, $temporaryRoot) -Description 'clone latest skill repository'
  $latestVersion = Read-SkillVersion -Root $temporaryRoot
  if ([string]::IsNullOrWhiteSpace($latestVersion)) {
    Write-Warning "Remote skill repository is missing $versionFile. Skipping installed skill version enforcement until metadata is available on $Branch."
    return
  }

  if (-not $Force -and $currentVersion -eq $latestVersion) {
    Write-Host "Installed skill is current: $latestVersion"
    return
  }

  $installedCount = Install-TrackedFiles -SourceRoot $temporaryRoot -DestinationRoot $installedRoot
  Write-Host "Installed skill updated from '$currentVersion' to '$latestVersion'."
  Write-Host "Files installed: $installedCount"
  throw 'Installed skill was updated. Restart Codex or start a new run so the updated skill instructions are loaded.'
} finally {
  if (Test-Path -LiteralPath $temporaryRoot) {
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
  }
}
