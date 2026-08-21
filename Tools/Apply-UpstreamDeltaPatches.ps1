[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$BaseRef,
    [string]$TargetRef = 'upstream/main',
    [string[]]$Skip = @('ZTPlayerController.uc', 'ZTHudWrapper.uc')
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

$packet = Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot $manifest.paths.changePackets) -Directory |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'conflicts') } |
    Sort-Object Name -Descending | Select-Object -First 1
if ($null -eq $packet) { throw 'No rename-aware conflict packet was found.' }
$audit = Get-Content -LiteralPath (Join-Path $packet.FullName 'changes.json') -Raw | ConvertFrom-Json
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('tempered-delta-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()

try {
    foreach ($conflict in Get-ChildItem -LiteralPath (Join-Path $packet.FullName 'conflicts') -Filter '*.uc') {
        if ($Skip -contains $conflict.Name) { continue }
        $change = @($audit.changes | Where-Object { @($_.temperedCandidates) -contains $conflict.Name }) | Select-Object -First 1
        if ($null -eq $change) { continue }

        $baseLines = @(git -C $RepositoryRoot show "${BaseRef}:$($change.upstreamPath)")
        if ($LASTEXITCODE -ne 0) { throw "Could not read base for $($conflict.Name)" }
        $targetLines = @(git -C $RepositoryRoot show "${TargetRef}:$($change.upstreamPath)")
        if ($LASTEXITCODE -ne 0) { throw "Could not read target for $($conflict.Name)" }

        $baseFile = Join-Path $tempRoot ('base-' + $conflict.Name)
        $targetFile = Join-Path $tempRoot ('target-' + $conflict.Name)
        [IO.File]::WriteAllText($baseFile, (($baseLines | ForEach-Object { Convert-UpstreamLine $_ }) -join "`n") + "`n", [Text.Encoding]::ASCII)
        [IO.File]::WriteAllText($targetFile, (($targetLines | ForEach-Object { Convert-UpstreamLine $_ }) -join "`n") + "`n", [Text.Encoding]::ASCII)

        $diff = @(& git diff --no-index --ignore-space-at-eol --ignore-cr-at-eol --unified=3 -- $baseFile $targetFile)
        if ($diff.Count -lt 4) { continue }
        $targetRepoPath = "ZedternalTempered/Classes/$($conflict.Name)"
        $diff[0] = "diff --git a/$targetRepoPath b/$targetRepoPath"
        $diff[2] = "--- a/$targetRepoPath"
        $diff[3] = "+++ b/$targetRepoPath"
        $patchFile = Join-Path $tempRoot ($conflict.BaseName + '.patch')
        [IO.File]::WriteAllText($patchFile, ($diff -join "`n") + "`n", [Text.Encoding]::ASCII)

        & git -C $RepositoryRoot apply --reject --ignore-space-change --ignore-whitespace $patchFile
        $exit = $LASTEXITCODE
        $reject = Join-Path $RepositoryRoot ($targetRepoPath + '.rej')
        $results.Add([pscustomobject]@{
            file = $conflict.Name
            applyExit = $exit
            hasReject = (Test-Path -LiteralPath $reject)
        })
    }
} finally {
    $resolvedTemp = [IO.Path]::GetFullPath($tempRoot)
    $resolvedTempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemp.StartsWith($resolvedTempBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedTemp) -like 'tempered-delta-*') {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        throw "Refusing to remove unexpected temporary path: $resolvedTemp"
    }
}

$results | Format-Table -AutoSize
Write-Host "Applied=$(@($results | Where-Object { -not $_.hasReject }).Count) PartialOrRejected=$(@($results | Where-Object hasReject).Count)"
