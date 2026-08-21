[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$BaseRef,
    [string]$TargetRef = 'upstream/main'
)

$ErrorActionPreference = 'Stop'

$manifestPath = Join-Path $RepositoryRoot 'UpstreamSync.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Missing upstream manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($BaseRef)) {
    $BaseRef = [string]$manifest.upstream.temperedBaseCommit
}

git -C $RepositoryRoot rev-parse --verify "$BaseRef^{commit}" *> $null
if ($LASTEXITCODE -ne 0) { throw "Unknown base ref: $BaseRef" }
git -C $RepositoryRoot rev-parse --verify "$TargetRef^{commit}" *> $null
if ($LASTEXITCODE -ne 0) { throw "Unknown target ref: $TargetRef" }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$packetRoot = Join-Path $RepositoryRoot (Join-Path $manifest.paths.changePackets $stamp)
New-Item -ItemType Directory -Path $packetRoot -Force | Out-Null

$upstreamPrefix = ([string]$manifest.paths.upstreamPackage).TrimEnd('/') + '/'
$temperedClasses = Join-Path $RepositoryRoot (Join-Path $manifest.paths.temperedPackage 'Classes')
$nameStatus = @(git -C $RepositoryRoot diff --name-status $BaseRef $TargetRef -- $manifest.paths.upstreamPackage)
if ($LASTEXITCODE -ne 0) { throw 'git diff failed' }

$changes = foreach ($line in $nameStatus) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line -split "`t"
    $status = $parts[0]
    $path = $parts[-1]
    $leaf = Split-Path -Leaf $path
    $candidates = [System.Collections.Generic.List[string]]::new()
    $candidates.Add($leaf)
    if ($leaf -match '^DK') { $candidates.Add(('ZT' + $leaf.Substring(2))) }
    if ($leaf -match '^Config_') { $candidates.Add(('ZTConfig_' + $leaf.Substring(7))) }
    $aliasProperty = $manifest.classAliases.PSObject.Properties[$leaf]
    if ($null -ne $aliasProperty) {
        foreach ($alias in @($aliasProperty.Value)) { $candidates.Add([string]$alias) }
    }

    $matches = @($candidates | Select-Object -Unique | Where-Object {
        Test-Path -LiteralPath (Join-Path $temperedClasses $_)
    })

    [pscustomobject]@{
        status = $status
        upstreamPath = $path
        upstreamClass = if ($leaf.EndsWith('.uc')) { $leaf.Substring(0, $leaf.Length - 3) } else { $null }
        temperedCandidates = $matches
        requiresReview = ($path.EndsWith('.uc') -or $path -match '/Localization/' -or $path -match '/Config/')
    }
}

$baseCommit = (git -C $RepositoryRoot rev-parse $BaseRef).Trim()
$targetCommit = (git -C $RepositoryRoot rev-parse $TargetRef).Trim()
$summary = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    baseRef = $BaseRef
    baseCommit = $baseCommit
    targetRef = $TargetRef
    targetCommit = $targetCommit
    changedFileCount = @($changes).Count
    reviewFileCount = @($changes | Where-Object requiresReview).Count
    changes = @($changes)
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $packetRoot 'changes.json') -Encoding utf8
$nameStatus | Set-Content -LiteralPath (Join-Path $packetRoot 'name-status.txt') -Encoding utf8
git -C $RepositoryRoot diff --binary $BaseRef $TargetRef -- $manifest.paths.upstreamPackage |
    Set-Content -LiteralPath (Join-Path $packetRoot 'upstream.patch') -Encoding utf8

$review = @($changes | Where-Object requiresReview)
$review | Select-Object status, upstreamPath, upstreamClass,
    @{Name='temperedCandidates';Expression={$_.temperedCandidates -join ';'}} |
    Export-Csv -LiteralPath (Join-Path $packetRoot 'review.csv') -NoTypeInformation -Encoding utf8

Write-Host "Created upstream change packet: $packetRoot"
Write-Host "Changed files: $(@($changes).Count); review candidates: $(@($review).Count)"
