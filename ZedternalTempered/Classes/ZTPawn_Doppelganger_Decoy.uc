// ===================================================================
// ZTPawn_Doppelganger_Decoy
//
// A short-lived illusory copy of the summoning player, for the Doppelganger
// perk. It is a real KFPawn_Human (so KF2's AI hunts it like any survivor -
// that is the "draws aggro" behaviour), but controllerless (never counted as a
// player, so it can't affect wave-end / living-player count) and weaponless
// (its "shots" are timed hitscan damage under the hood, not a real gun).
//
// TRUE LIKENESS: on spawn the helper feeds the decoy the owner's PRI. On each
// client the decoy dresses itself from that PRI via the game's own customization
// path (KFCharacterInfo_Human.SetCharacterMeshFromArch), which reproduces the
// owner's exact character + outfit + cosmetic attachments (hats/backpacks).
//
// LIFECYCLE (server): InitDecoy() configures + starts a repeating auto-fire
// timer and a one-shot lifespan timer. On lifespan expiry or death it detonates
// (capstone 20 only) and is removed.
//
// The helper (ZTUpgrade_Perk_Doppelganger_Helper) owns spawning, counting, and
// cleanup; this pawn only knows how to look like you, draw fire, shoot, and end.
// ===================================================================
class ZTPawn_Doppelganger_Decoy extends KFPawn_Human;

// Appearance source - replicated so every client can dress the decoy like the
// owner. Set once on spawn (server) to the summoning player's PRI.
var repnotify KFPlayerReplicationInfo SourcePRI;

// Runtime config (server-authoritative), set by the helper right after Spawn.
var Controller OwnerPC;         // summoning player's controller (kill credit)
var int   DecoyHitDamage;       // damage dealt per auto-fire tick
var float DecoyFireInterval;    // seconds between auto-fire ticks
var float DecoyFireRange;       // auto-fire reach (uu)
var float DecoyLifeSeconds;     // how long the decoy lives
var bool  bDetonateOnEnd;       // capstone 20: burst on death/expiry
var int   DetonateDamage;
var float DetonateRadius;

// Client bookkeeping: apply the likeness exactly once.
var transient bool bDressed;

replication
{
    if (bNetDirty)
        SourcePRI;
}

// ===================================================================
// SETUP (server) - called by the helper immediately after Spawn.
// ===================================================================
function InitDecoy(KFPawn_Human Source, Controller InOwnerPC, int InDamage,
    float InInterval, float InRange, float InLife,
    bool InDetonate, int InDetDmg, float InDetRadius)
{
    OwnerPC           = InOwnerPC;
    DecoyHitDamage    = InDamage;
    DecoyFireInterval = InInterval;
    DecoyFireRange    = InRange;
    DecoyLifeSeconds  = InLife;
    bDetonateOnEnd    = InDetonate;
    DetonateDamage    = InDetDmg;
    DetonateRadius    = InDetRadius;

    if (Source != None)
        SourcePRI = KFPlayerReplicationInfo(Source.PlayerReplicationInfo);

    // Draw aggro like a normal survivor.
    bAIZedsIgnoreMe = false;

    // Dress on a listen server / standalone host too (replication covers remotes).
    ApplyLikeness();

    // Auto-fire loop + lifespan.
    SetTimer(FMax(DecoyFireInterval, 0.1f), true, 'DecoyFireTick');
    SetTimer(FMax(DecoyLifeSeconds, 1.0f), false, 'DecoyExpire');
}

// A decoy is not a real soldier - it never receives the human default kit
// (syringe/welder/money). Its damage is dealt directly in DecoyFireTick.
function AddDefaultInventory()
{
}

// ===================================================================
// APPEARANCE (client + listen host) - true likeness of the owner.
// ===================================================================
simulated event ReplicatedEvent(name VarName)
{
    if (VarName == 'SourcePRI')
    {
        ApplyLikeness();
        return;
    }
    super.ReplicatedEvent(VarName);
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    ApplyLikeness();
}

simulated function ApplyLikeness()
{
    local KFCharacterInfo_Human CharInfo;

    if (bDressed || SourcePRI == None || WorldInfo.NetMode == NM_DedicatedServer)
        return;

    if (SourcePRI.RepCustomizationInfo.CharacterIndex >= SourcePRI.CharacterArchetypes.Length)
        return;

    // CharacterArchetypes is already array<KFCharacterInfo_Human> - no cast.
    CharInfo = SourcePRI.CharacterArchetypes[SourcePRI.RepCustomizationInfo.CharacterIndex];
    if (CharInfo == None)
        return;

    // Dress THIS pawn from the owner's PRI: body + head + outfit + cosmetic
    // attachments, via the game's own customization code = a true likeness.
    CharInfo.SetCharacterMeshFromArch(self, SourcePRI);
    bDressed = true;
}

// Force onto the survivor team so zeds treat the decoy as a target (aggro) and
// teammates never hit it.
simulated function byte GetTeamNum()
{
    return 0;
}

// ===================================================================
// AUTO-FIRE (server) - fixed damage to the nearest visible zed in range,
// credited to the summoning player so kills count normally.
// ===================================================================
function DecoyFireTick()
{
    local KFPawn_Monster KFM, Best;
    local float BestDistSq, DistSq;

    if (Role != ROLE_Authority || Health <= 0)
        return;

    BestDistSq = DecoyFireRange * DecoyFireRange;
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFM, Location, DecoyFireRange)
    {
        if (!KFM.IsAliveAndWell() || KFM.GetTeamNum() != 255)
            continue;

        DistSq = VSizeSq(KFM.Location - Location);
        if (DistSq <= BestDistSq)
        {
            // Require a clear shot so the decoy doesn't fire through walls.
            if (FastTrace(KFM.Location + vect(0,0,32), Location + vect(0,0,48)))
            {
                Best = KFM;
                BestDistSq = DistSq;
            }
        }
    }

    if (Best != None)
    {
        Best.TakeDamage(DecoyHitDamage, OwnerPC, Best.Location,
            Normal(Best.Location - Location) * 1000.0f,
            class'KFDamageType', , self);
    }
}

// ===================================================================
// END-OF-LIFE
// ===================================================================
function DecoyExpire()
{
    EndDecoy();
}

// Zed focus-fire killed the decoy: detonate (capstone) then let death proceed.
function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
    ClearTimer('DecoyFireTick');
    ClearTimer('DecoyExpire');
    DoDetonate();
    return super.Died(Killer, DamageType, HitLocation);
}

// Lifespan elapsed: detonate (capstone) then remove cleanly.
function EndDecoy()
{
    ClearTimer('DecoyFireTick');
    ClearTimer('DecoyExpire');

    // Already dying/dead - death path handles teardown.
    if (Health <= 0 || bDeleteMe)
        return;

    DoDetonate();
    Destroy();
}

// Capstone 20: an AoE burst that damages nearby zeds on death/expiry.
function DoDetonate()
{
    local KFPawn_Monster KFM;

    if (Role != ROLE_Authority || !bDetonateOnEnd || DetonateDamage <= 0)
        return;

    bDetonateOnEnd = false;   // only once

    foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFM, Location, DetonateRadius)
    {
        if (!KFM.IsAliveAndWell() || KFM.GetTeamNum() != 255)
            continue;

        KFM.TakeDamage(DetonateDamage, OwnerPC, KFM.Location,
            Normal(KFM.Location - Location) * 5000.0f,
            class'KFDamageType', , self);
    }
}

defaultproperties
{
}
