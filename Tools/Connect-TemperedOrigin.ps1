[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$OriginUrl,
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$PushIntegration
)

$ErrorActionPreference = 'Stop'
git -C $RepositoryRoot rev-parse --git-dir *> $null
if ($LASTEXITCODE -ne 0) { throw "Not a Git repository: $RepositoryRoot" }

$existing = git -C $RepositoryRoot remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    if ($existing.Trim() -ne $OriginUrl.Trim()) {
        throw "origin already points somewhere else: $existing"
    }
} else {
    git -C $RepositoryRoot remote add origin $OriginUrl
    if ($LASTEXITCODE -ne 0) { throw 'Could not add the Tempered origin remote.' }
}

git -C $RepositoryRoot push -u origin tempered-main
if ($LASTEXITCODE -ne 0) { throw 'Failed to push tempered-main.' }
git -C $RepositoryRoot push origin --tags
if ($LASTEXITCODE -ne 0) { throw 'Failed to push Tempered tags.' }

if ($PushIntegration) {
    $branches = @(git -C $RepositoryRoot for-each-ref --format='%(refname:short)' 'refs/heads/integration/*')
    foreach ($branch in $branches) {
        git -C $RepositoryRoot push -u origin $branch
        if ($LASTEXITCODE -ne 0) { throw "Failed to push $branch." }
    }
}

Write-Host '[DONE] Tempered Git history is connected and pushed.'
