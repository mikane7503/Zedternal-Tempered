[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$BaseRef,
    [string]$TargetRef = 'upstream/main'
)

$ErrorActionPreference = 'Stop'
$manifest = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'UpstreamSync.json') -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($BaseRef)) { $BaseRef = [string]$manifest.upstream.temperedBaseCommit }

function Convert-UpstreamLine([string]$Line) {
    $parts = $Line -split '"', -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $parts[$i] = $parts[$i].Replace('ZedternalRBPerkpackage.', 'ZedternalTempered.')
        if (($i % 2) -eq 0) {
            $parts[$i] = [regex]::Replace($parts[$i], '(?<![A-Za-z0-9])DK(?!Mutator\b)(?=[A-Z_])', 'ZT')
        } else {
            $parts[$i] = $parts[$i].Replace('Default__DK', 'Default__ZT')
        }
    }
    return ($parts -join '"')
}

& (Join-Path $PSScriptRoot 'New-UpstreamChangePacket.ps1') -RepositoryRoot $RepositoryRoot -BaseRef $BaseRef -TargetRef $TargetRef | Out-Host
$packet = Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot $manifest.paths.changePackets) -Directory |
    Sort-Object Name -Descending | Select-Object -First 1
$audit = Get-Content -LiteralPath (Join-Path $packet.FullName 'changes.json') -Raw | ConvertFrom-Json
$classRoot = Join-Path $RepositoryRoot (Join-Path $manifest.paths.temperedPackage 'Classes')
$added = [System.Collections.Generic.List[string]]::new()

foreach ($change in @($audit.changes | Where-Object {
    $_.status -like 'A*' -and $_.upstreamPath -like '*.uc'
})) {
    $leaf = Split-Path -Leaf $change.upstreamPath
    $targetLeaf = if ($leaf -match '^DK') { 'ZT' + $leaf.Substring(2) } else { $leaf }
    $targetPath = Join-Path $classRoot $targetLeaf
    if (Test-Path -LiteralPath $targetPath) {
        Write-Host "[EXISTS] $targetLeaf"
        continue
    }

    $lines = @(git -C $RepositoryRoot show "${TargetRef}:$($change.upstreamPath)")
    if ($LASTEXITCODE -ne 0) { throw "Could not read ${TargetRef}:$($change.upstreamPath)" }
    $text = (($lines | ForEach-Object { Convert-UpstreamLine $_ }) -join "`n") + "`n"
    [IO.File]::WriteAllText($targetPath, $text, [Text.Encoding]::ASCII)
    $added.Add($targetLeaf)
    Write-Host "[ADDED ] $targetLeaf"
}

$added | Set-Content -LiteralPath (Join-Path $packet.FullName 'added-classes.txt') -Encoding utf8
Write-Host "Added $($added.Count) new Tempered classes. Registration and localization still require review."
