[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$UpstreamRef = 'upstream/main',
    [string]$Label = (Get-Date -Format 'yyyy-MM-dd')
)

$ErrorActionPreference = 'Stop'
$dirty = @(git -C $RepositoryRoot status --porcelain)
if ($LASTEXITCODE -ne 0) { throw "Not a Git repository: $RepositoryRoot" }
if ($dirty.Count -gt 0) { throw 'Working tree is not clean. Commit or stash changes first.' }

git -C $RepositoryRoot fetch upstream --tags
if ($LASTEXITCODE -ne 0) { throw 'Failed to fetch the official Unlimited remote.' }

$branch = "integration/unlimited-$Label"
git -C $RepositoryRoot show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) { throw "Integration branch already exists: $branch" }

git -C $RepositoryRoot switch tempered-main
if ($LASTEXITCODE -ne 0) { throw 'Could not switch to tempered-main.' }
git -C $RepositoryRoot switch -c $branch
if ($LASTEXITCODE -ne 0) { throw "Could not create $branch." }

git -C $RepositoryRoot merge --no-ff $UpstreamRef -m "Stage $UpstreamRef for Tempered integration ($Label)"
if ($LASTEXITCODE -ne 0) {
    throw 'Upstream merge needs manual conflict resolution. No Tempered deployment was attempted.'
}

& (Join-Path $PSScriptRoot 'New-UpstreamChangePacket.ps1') -RepositoryRoot $RepositoryRoot -TargetRef $UpstreamRef
Write-Host "[READY] Review branch $branch. Build with Build-Deploy-Tempered.ps1 -SkipDeploy."
