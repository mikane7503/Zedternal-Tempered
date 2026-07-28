// ===================================================================
// DKProj_DetonatorGroundFire - Slow Burn ground fire pool
//
// Spawned by the Detonator helper at the detonation site when the
// Slow Burn skill is owned. Applies AoE fire DoT to monsters within
// radius for the configured duration, then self-destructs.
//
// Standard tier:  6s @ 30 dps
// Deluxe tier:   10s @ 60 dps
//
// HotPepper-style invisible AoE timer; relies on the parent
// detonation's explosion FX for visual feedback. Add a particle
// component later if you want a distinct flame effect.
//
// The helper writes Duration / DamagePerTick / RadiusSq / InstigatorPC
// after Spawn returns -- defaults below are placeholders.
// ===================================================================
class DKProj_DetonatorGroundFire extends Info
    transient;

var float Duration;             // total lifetime in seconds
var int DamagePerTick;          // damage applied each tick
var float RadiusSq;             // squared radius for fast distance checks
var KFPlayerController InstigatorPC;

const TICK_INTERVAL = 0.5f;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    if (Role == Role_Authority)
    {
        SetTimer(TICK_INTERVAL, true, 'DamageTick');
        SetTimer(Duration, false, 'EndFire');
    }
}

function DamageTick()
{
    local KFPawn_Monster KFM;

    if (InstigatorPC == None)
    {
        Destroy();
        return;
    }

    foreach DynamicActors(class'KFPawn_Monster', KFM)
    {
        if (KFM != None && KFM.IsAliveAndWell()
            && VSizeSQ(KFM.Location - Location) <= RadiusSq)
        {
            KFM.ApplyDamageOverTime(DamagePerTick, InstigatorPC,
                class'ZedternalReborn.WMDT_Napalm');
        }
    }
}

function EndFire()
{
    ClearTimer('DamageTick');
    Destroy();
}

defaultproperties
{
    Duration=6.0f
    DamagePerTick=15            // 30 dps * 0.5s tick
    RadiusSq=90000.0f           // 300 * 300

    bHidden=True
    bCollideActors=False
    bBlockActors=False

    Name="Default__DKProj_DetonatorGroundFire"
}
