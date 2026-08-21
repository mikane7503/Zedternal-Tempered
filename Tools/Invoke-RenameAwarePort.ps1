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
            $parts[$i] = [regex]::Replace(
                $parts[$i],
                '(?<![A-Za-z0-9])DK(?!Mutator\b)(?=[A-Z_])',
                'ZT')
        } else {
            $parts[$i] = $parts[$i].Replace('Default__DK', 'Default__ZT')
        }
    }
    return ($parts -join '"')
}

function Get-GitText([string]$Ref, [string]$Path) {
    $lines = @(git -C $RepositoryRoot show "${Ref}:$Path")
    if ($LASTEXITCODE -ne 0) { throw "Could not read ${Ref}:$Path" }
    return (($lines | ForEach-Object { Convert-UpstreamLine $_ }) -join "`n") + "`n"
}

$packetScript = Join-Path $PSScriptRoot 'New-UpstreamChangePacket.ps1'
& $packetScript -RepositoryRoot $RepositoryRoot -BaseRef $BaseRef -TargetRef $TargetRef | Out-Host
$packet = Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot $manifest.paths.changePackets) -Directory |
    Sort-Object Name -Descending | Select-Object -First 1
$audit = Get-Content -LiteralPath (Join-Path $packet.FullName 'changes.json') -Raw | ConvertFrom-Json

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('tempered-port-' + [guid]::NewGuid().ToString('N'))
$conflictRoot = Join-Path $packet.FullName 'conflicts'
New-Item -ItemType Directory -Path $tempRoot, $conflictRoot -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()

try {
    foreach ($change in @($audit.changes | Where-Object {
        $_.status -like 'M*' -and $_.upstreamPath -like '*.uc'
    })) {
        $candidates = @($change.temperedCandidates)
        if ($candidates.Count -ne 1) {
            $results.Add([pscustomobject]@{ upstream=$change.upstreamPath; tempered=$null; result='manual-no-single-target' })
            continue
        }

        $leaf = Split-Path -Leaf $change.upstreamPath
        $mechanicalLeaf = if ($leaf -match '^DK') { 'ZT' + $leaf.Substring(2) } else { $leaf }
        $targetLeaf = [string]$candidates[0]
        if ($targetLeaf -ne $mechanicalLeaf) {
            $results.Add([pscustomobject]@{ upstream=$change.upstreamPath; tempered=$targetLeaf; result='manual-alias' })
            continue
        }

        $ours = Join-Path $RepositoryRoot (Join-Path $manifest.paths.temperedPackage (Join-Path 'Classes' $targetLeaf))
        $baseFile = Join-Path $tempRoot ('base-' + $targetLeaf)
        $theirsFile = Join-Path $tempRoot ('theirs-' + $targetLeaf)
        [IO.File]::WriteAllText($baseFile, (Get-GitText $BaseRef $change.upstreamPath), [Text.Encoding]::ASCII)
        [IO.File]::WriteAllText($theirsFile, (Get-GitText $TargetRef $change.upstreamPath), [Text.Encoding]::ASCII)

        $merged = @(& git merge-file -p -- $ours $baseFile $theirsFile)
        $exit = $LASTEXITCODE
        $mergedText = ($merged -join "`n") + "`n"
        if ($exit -eq 0) {
            [IO.File]::WriteAllText($ours, $mergedText, [Text.Encoding]::ASCII)
            $results.Add([pscustomobject]@{ upstream=$change.upstreamPath; tempered=$targetLeaf; result='auto-merged' })
        } elseif ($exit -ge 1 -and $exit -le 127) {
            [IO.File]::WriteAllText((Join-Path $conflictRoot $targetLeaf), $mergedText, [Text.Encoding]::ASCII)
            $results.Add([pscustomobject]@{ upstream=$change.upstreamPath; tempered=$targetLeaf; result='manual-conflict' })
        } else {
            throw "git merge-file failed for $targetLeaf with exit code $exit"
        }
    }
} finally {
    $resolvedTemp = [IO.Path]::GetFullPath($tempRoot)
    $resolvedTempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemp.StartsWith($resolvedTempBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedTemp) -like 'tempered-port-*') {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        throw "Refusing to remove unexpected temporary path: $resolvedTemp"
    }
}

$reportPath = Join-Path $packet.FullName 'port-results.json'
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportPath -Encoding utf8
$results | Group-Object result | Select-Object Name, Count | Format-Table -AutoSize
Write-Host "Port report: $reportPath"
