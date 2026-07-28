// ===================================================================
// DKPawn_ZedPatriarch_Puppet
//
// Puppet-Master-only Patriarch for the [PUPPET] transform spike.
//
// Identical to the stock human-controllable Versus Patriarch EXCEPT that it
// reports IsABoss()=false. That single change makes the whole game treat it as
// an ordinary (large) zed - exactly as ZR already does for its own
// WMPawn_ZedPatriarch in Endless. It removes:
//   - the boss health bar (SetupHealthBar in KFPawn_Monster.PostBeginPlay is
//     IsABoss-gated),
//   - the boss_spawn analytics,
//   - the boss-death cam,
//   - and any wave-boss tracking,
// which is what softlocked the wave when the spike spawned the stock,
// boss-tagged KFPawn_ZedPatriarch_Versus. The _Versus parent still supplies the
// full player-control ability kit (SM_PlayerZedMove special-move bindings +
// SpecialMoveCooldowns HUD data), so the form plays exactly as before.
//
// Safe because nothing in the Patriarch (stock or Versus) ever READS IsABoss()
// to gate its abilities or phases, and ZR already runs an IsABoss()=false
// Patriarch in Endless.
//
// *** REMOVE BEFORE SHIPPING - throwaway [PUPPET] spike ***
// ===================================================================
class DKPawn_ZedPatriarch_Puppet extends KFPawn_ZedPatriarch_Versus;

// Treat as a normal zed everywhere boss-ness is checked.
static simulated event bool IsABoss()
{
    return false;
}

// KFPawn_MonsterBoss.PossessedBy calls PlayBossMusic() unconditionally (it is
// NOT IsABoss-gated), so silence it the way ZR does - otherwise taking over the
// puppet would blast Patriarch boss music on possession.
function PlayBossMusic()
{
}

// Puppet-Master mortar retargeting. The human-controllable Patriarch's mortar
// (KFPawn_ZedPatriarch_Versus.CollectMortarTargets) hunts KFPawn_Human - which
// in ZU survival is our own team. Retarget it at KFPawn_Monster (the actual
// enemies) instead, skipping ourselves and any other player-driven puppet so
// we never bombard our own side. Mirrors the stock Versus logic, KFPawn_Monster-
// typed; MortarTargets.TargetPawn is a plain KFPawn, so zeds store fine. The
// 3000uu AllPawns radius bounds the scan to the mortar's ~2500uu max range
// (the exact Min/MaxMortarRangeSQ check below still governs eligibility).
function bool CollectMortarTargets(optional bool bInitialTarget, optional bool bForceInitialTarget)
{
    local int NumTargets;
    local KFPawn_Monster KFM;
    local float TargetDistSQ;
    local vector MortarVelocity, MortarStartLoc, TargetLoc, TargetProjection;

    MortarStartLoc = Location + vect(0,0,1) * GetCollisionHeight();
    NumTargets = bInitialTarget ? 0 : 1;

    foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFM, MortarStartLoc, 3000.0f)
    {
        // Skip dead, self, already-picked, and any player-controlled monster
        // (that is us or a teammate's puppet - never mortar our own side).
        if (!KFM.IsAliveAndWell() || KFM == self
            || PlayerController(KFM.Controller) != None
            || MortarTargets.Find('TargetPawn', KFM) != INDEX_NONE)
        {
            continue;
        }

        TargetLoc = KFM.Location + (vect(0,0,-1) * (KFM.GetCollisionHeight() * 0.8f));
        TargetProjection = MortarStartLoc - TargetLoc;
        TargetDistSQ = VSizeSQ(TargetProjection);
        if (TargetDistSQ > MinMortarRangeSQ && TargetDistSQ < MaxMortarRangeSQ)
        {
            TargetLoc += Normal(TargetProjection) * KFM.GetCollisionRadius();
            if (SuggestTossVelocity(MortarVelocity, TargetLoc, MortarStartLoc, MortarProjectileClass.default.Speed, 500.f, 1.f, vect(0,0,0),, GetGravityZ() * 0.8f))
            {
                // Make sure the upward arc path is clear.
                if (!FastTrace(MortarStartLoc + (Normal(vect(0,0,1) + (Normal(TargetLoc - MortarStartLoc) * 0.9f)) * fMax(VSize(MortarVelocity) * 0.55f, 800.f)), MortarStartLoc,, true))
                {
                    continue;
                }

                MortarTargets.Insert(NumTargets, 1);
                MortarTargets[NumTargets].TargetPawn = KFM;
                MortarTargets[NumTargets].TargetVelocity = MortarVelocity;

                if (bInitialTarget || NumTargets == 2)
                {
                    return true;
                }

                NumTargets++;
            }
        }
    }

    return false;
}

defaultproperties
{
}
