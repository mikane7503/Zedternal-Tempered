[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$SkipDeploy
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = $PSScriptRoot
$PackageRoot = Join-Path $ProjectRoot 'ZedternalTempered'
$GameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\killingfloor2'
$SdkSourceRoot = 'C:\Users\yss19\Documents\My Games\KillingFloor2\KFGame\Src'
$SdkSource = Join-Path $SdkSourceRoot 'ZedternalTempered'
$EditorExe = Join-Path $GameRoot 'Binaries\Win64\KFEditor.exe'
$BuiltScript = 'C:\Users\yss19\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Script\ZedternalTempered.u'

$ServerBrewed = 'D:\KF2server\KFGame\BrewedPC'
$Redirect = 'D:\KF2server\redirect'
$ClientKor = 'C:\Users\yss19\Documents\My Games\KillingFloor2\KFGame\Localization\KOR'
$ClientMenuCacheRoots = @(
    'C:\Users\yss19\Documents\My Games\KillingFloor2\KFGame\Cache',
    (Join-Path $GameRoot 'Binaries\Win64\Game\Config\My Games\KillingFloor2\KFGame\Cache')
)
$ServerConfig = 'D:\KF2server\KFGame\Config\SV_Zedternal_Tempered'
$ResourceRoot = 'C:\Users\yss19\Documents\Projects\Zedternal Unlimited Rebalance\source'

function Assert-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Copy-IfChanged([string]$Source, [string]$DestinationDirectory) {
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "Deployment source does not exist: $Source"
    }

    Assert-Directory $DestinationDirectory
    $Destination = Join-Path $DestinationDirectory (Split-Path $Source -Leaf)
    $SourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Source).Hash
    $DestinationHash = if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        (Get-FileHash -Algorithm SHA256 -LiteralPath $Destination).Hash
    } else {
        ''
    }

    if ($SourceHash -ne $DestinationHash) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        $CopiedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Destination).Hash
        if ($CopiedHash -ne $SourceHash) {
            throw "Hash verification failed after copying to: $Destination"
        }
        Write-Host "[DEPLOYED] $Destination"
    } else {
        Write-Host "[CURRENT ] $Destination"
    }
}

foreach ($Directory in @($ServerBrewed, $Redirect, $ClientKor, $ServerConfig)) {
    Assert-Directory $Directory
}

if (-not $SkipBuild) {
    if (-not (Test-Path -LiteralPath $EditorExe -PathType Leaf)) {
        throw "KFEditor.exe was not found: $EditorExe"
    }

    $ExpectedSdkSource = Join-Path $SdkSourceRoot 'ZedternalTempered'
    if ([IO.Path]::GetFullPath($SdkSource) -ne [IO.Path]::GetFullPath($ExpectedSdkSource)) {
        throw "Refusing to mirror source to unexpected path: $SdkSource"
    }

    Assert-Directory $SdkSource
    & robocopy $PackageRoot $SdkSource /MIR /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -gt 7) {
        throw "Source staging failed with robocopy exit code $LASTEXITCODE"
    }

    $BuildStarted = Get-Date
    Write-Host '[BUILD   ] KFEditor make -full'
    $Process = Start-Process -FilePath $EditorExe -ArgumentList @('make', '-full', '-unattended', '-nopause') -WorkingDirectory (Split-Path $EditorExe) -Wait -PassThru
    if ($Process.ExitCode -ne 0) {
        throw "KFEditor exited with code $($Process.ExitCode)"
    }

    if (-not (Test-Path -LiteralPath $BuiltScript -PathType Leaf)) {
        throw "Build output was not produced: $BuiltScript"
    }
    if ((Get-Item -LiteralPath $BuiltScript).LastWriteTime -lt $BuildStarted.AddSeconds(-2)) {
        throw "Build output timestamp was not updated: $BuiltScript"
    }

    $LatestBuildLog = Get-ChildItem 'C:\Users\yss19\Documents\My Games\KillingFloor2\KFGame\Logs' -Filter 'Launch*.log' -File |
        Where-Object { $_.LastWriteTime -ge $BuildStarted.AddSeconds(-2) } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $LatestBuildLog) {
        throw 'Could not locate the KFEditor build log.'
    }
    if (-not (Select-String -LiteralPath $LatestBuildLog.FullName -SimpleMatch 'Success - 0 error(s)' -Quiet)) {
        throw "KFEditor did not report a successful zero-error build: $($LatestBuildLog.FullName)"
    }
}

if ($SkipDeploy) {
    Write-Host '[DONE    ] Tempered build validation completed; deployment was skipped.'
    return
}

# A running server may keep the old package loaded until its next restart.
$RunningServer = Get-Process -Name 'KFGame' -ErrorAction SilentlyContinue
if ($RunningServer) {
    Write-Warning 'KFGame is running. Files will be deployed, but the server must be restarted to load the new build.'
}

# Mutator script goes to both server runtime and redirect.
Copy-IfChanged $BuiltScript $ServerBrewed
Copy-IfChanged $BuiltScript $Redirect

# Tempered perk artwork and the Reborn packages it references.
$ResourcePackages = @(
    'ZedternalRBPerkpackage_Resources.upk',
    'ZedternalRBPerkpackage_Menus.upk',
    'ZedternalReborn_Resource.upk',
    'ZedternalReborn_Menus.upk',
    'ZedternalReborn_Zeds.upk'
)
foreach ($PackageName in $ResourcePackages) {
    $SourcePackage = Join-Path $ResourceRoot $PackageName
    Copy-IfChanged $SourcePackage $ServerBrewed
    Copy-IfChanged $SourcePackage $Redirect
}

# Keep the SDK/client copies on the unmodified Reborn menu package. This is a
# stock-resource deployment, not a generated Tempered UI fork.
$OriginalMenuPackage = Join-Path $ResourceRoot 'ZedternalReborn_Menus.upk'
$SdkUnpublishedBrewed = 'C:\Users\yss19\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC'
Copy-IfChanged $OriginalMenuPackage $SdkUnpublishedBrewed
foreach ($CacheRoot in $ClientMenuCacheRoots) {
    if (-not (Test-Path -LiteralPath $CacheRoot -PathType Container)) { continue }
    Get-ChildItem -LiteralPath $CacheRoot -Recurse -File -Filter 'ZedternalReborn_Menus.upk' | ForEach-Object {
        Copy-IfChanged $OriginalMenuPackage $_.DirectoryName
    }
}

# Korean localization is client-side; deploy every Tempered KOR payload.
Get-ChildItem -LiteralPath (Join-Path $PackageRoot 'Localization\KOR') -Filter '*.kor' -File | ForEach-Object {
    Copy-IfChanged $_.FullName $ClientKor
}

# All Tempered INI defaults are server-profile configuration.
Get-ChildItem -LiteralPath $PackageRoot -Filter '*.ini' -File | ForEach-Object {
    Copy-IfChanged $_.FullName $ServerConfig
}

Write-Host '[DONE    ] Tempered build and four-root deployment completed with SHA-256 verification.'
