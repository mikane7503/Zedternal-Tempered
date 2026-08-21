# Zedternal Unlimited Tempered

Tempered is an independent Killing Floor 2 Zedternal package derived from
Zedternal Reborn and Zedternal Unlimited. It preserves Tempered-specific
balance, perks, skills, localization and server behavior while tracking the
official Unlimited source as an upstream.

- Tempered package: `ZedternalTempered`
- Official Unlimited upstream: <https://github.com/DukeLindenhurst/zedternal-unlimited>
- Server URL: `Game=ZedternalTempered.ZTGameInfo_Endless?mutator=ZedternalTempered.DKMutator`
- Language: UnrealScript (UE3)

## Branches

- `tempered-main`: verified Tempered source and workflow
- `integration/unlimited-*`: isolated Unlimited update review branches
- `main`: current published integration state

The tag `tempered-baseline-2026-08-21` preserves the first Git-backed Tempered
baseline. Do not merge an integration branch into the verified branch until its
changes have been ported to `ZedternalTempered`, compiled and tested in game.

## Repository layout

- `ZedternalRBPerkpackage`: read-only official Unlimited comparison tree
- `ZedternalTempered`: independent Tempered gameplay package
- `Zedternal-Reborn-master`: Reborn build dependency
- `Tools`: upstream audit and synchronization helpers
- `Docs/UPSTREAM-SYNC.md`: update procedure and safety rules

Generated `.u` files, the 856 MB resource UPK, server deployments and build
output are intentionally excluded from Git history. Version large packaged
artifacts separately; do not use them as source merge inputs.

## Building

Run `Build-Deploy-Tempered.bat` for the established local test deployment. For
a compile-only integration gate with no server, redirect, INI or KOR deployment:

```powershell
.\Build-Deploy-Tempered.ps1 -SkipDeploy
```

Required compile order:

1. `ZedternalReborn`
2. `ZedternalTempered`

Howdy, Psyk0tik and Tainted Hex packages are not Tempered dependencies.

## Unlimited updates

Start a new isolated upstream review with:

```powershell
.\Tools\Start-UpstreamIntegration.ps1
```

The command fetches official Unlimited, creates an integration branch and
generates a compact change packet. It never deploys the game. See
`Docs/UPSTREAM-SYNC.md` before porting changes.

## Source integrity

- `.gitattributes` disables automatic text conversion for UnrealScript and
  UTF-16 localization files.
- Keep Tempered-only behavior in `ZedternalTempered`.
- Keep the upstream comparison package unmodified.
- Promote updates only after zero-error compilation and in-game regression
  testing.
