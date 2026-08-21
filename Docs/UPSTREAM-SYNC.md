# Unlimited -> Tempered update workflow

`tempered-main` descends from Unlimited commit
`9a50dba2642c8501ad147ee8832c5d6b424d4530`. The upstream package remains in
the repository as a read-only comparison tree. Tempered gameplay code lives in
`ZedternalTempered`.

Never copy Workshop `.u` or `.upk` files over the source tree. They are build or
release artifacts, not merge inputs.

## Update procedure

1. Fetch official history: `git fetch upstream --tags`.
2. Create an integration branch from `tempered-main`.
3. Run `Tools/New-UpstreamChangePacket.ps1` before merging.
4. Merge `upstream/main` with `--no-commit --no-ff`.
5. Review the generated packet and port affected upstream classes to their `ZT`
   counterparts. Tempered-only classes and balance remain authoritative.
6. Build and run the static/localization/resource checks.
7. Test on the integration server profile.
8. Merge the integration branch into `tempered-main` only after all gates pass.
9. Tag the accepted build and deploy it.

`UpstreamSync.json` stores the last accepted upstream base. Update
`temperedBaseCommit` only after an Unlimited update has been fully ported and
verified, not merely fetched or merged into the reference tree.
