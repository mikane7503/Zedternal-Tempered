// ===================================================================
// ZTUpgrade_Skill_ShatterPoint_Helper — Per-Target Damage Tracker
//
// Tracks cumulative damage dealt to each individual zed. When the
// damage dealt exceeds a threshold (% of target's max HP), the
// Shatter Point triggers: bonus damage equal to a % of target's
// max HP is added, and the tracker resets for that target.
// Can trigger multiple times on the same target (boss fights).
//
// Periodically cleans up entries for dead zeds to prevent
// unbounded array growth during long waves.
//
// Sound: Plays 'Artificer_Shatter_Point' on proc via ZTSoundManager.
// ===================================================================
class ZTUpgrade_Skill_ShatterPoint_Helper extends Info;

var int UpgradeLevel;
var KFPawn_Human Player;

// Per-target stress fracture tracking
struct SStressFracture
{
    var KFPawn_Monster Target;
    var float DamageDealt;
    var int TargetMaxHP;        // Cached on first hit for consistency
};
var array<SStressFracture> Fractures;

// Cleanup throttle
var float LastCleanupTime;
var const float CleanupInterval;

// ===================================================================
// INITIALIZATION
// ===================================================================

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    LastCleanupTime = WorldInfo.TimeSeconds;
}

// ===================================================================
// ON HIT — Called from ZTUpgrade_Skill_ShatterPoint.ModifyDamageGiven
// Tracks damage, checks threshold, applies burst if met.
// ===================================================================

function OnHit(KFPawn_Monster Target, out int InDamage, int DefaultDamage, int upgLevel)
{
    local int Idx;
    local float Threshold, BurstPct;
    local int BurstDamage;
    local float CurrentTime;

    if (Player == None || Target == None)
        return;

    // Periodic cleanup of dead targets
    CurrentTime = WorldInfo.TimeSeconds;
    if ((CurrentTime - LastCleanupTime) > CleanupInterval)
    {
        CleanupDeadTargets();
        LastCleanupTime = CurrentTime;
    }

    // Find or create fracture entry for this target
    Idx = FindOrCreateFracture(Target);
    if (Idx == INDEX_NONE)
        return;

    // Accumulate damage dealt (use the actual damage being dealt, not default)
    Fractures[Idx].DamageDealt += float(InDamage);

    // Calculate threshold in absolute HP
    Threshold = float(Fractures[Idx].TargetMaxHP) * class'ZTUpgrade_Skill_ShatterPoint'.default.DamageThreshold[upgLevel - 1];

    // Check if we've crossed the threshold
    if (Fractures[Idx].DamageDealt >= Threshold)
    {
        // SHATTER POINT — calculate burst damage as % of target's max HP
        BurstPct = class'ZTUpgrade_Skill_ShatterPoint'.default.BurstPercent[upgLevel - 1];
        BurstDamage = Round(float(Fractures[Idx].TargetMaxHP) * BurstPct);

        // Apply burst
        InDamage += BurstDamage;

        // Reset tracker (can trigger again on same target)
        Fractures[Idx].DamageDealt = 0.f;

        // Play shatter sound
        PlayShatterSound('Artificer_Shatter_Point');

        `log("ZR ShatterPoint: SHATTER! +" $ BurstDamage @ "damage on" @ Target @ "(MaxHP=" $ Fractures[Idx].TargetMaxHP $ ")");
    }
}

// ===================================================================
// FRACTURE ARRAY MANAGEMENT
// ===================================================================

function int FindOrCreateFracture(KFPawn_Monster Target)
{
    local int i;
    local SStressFracture NewEntry;

    // Search existing entries
    for (i = 0; i < Fractures.Length; ++i)
    {
        if (Fractures[i].Target == Target)
            return i;
    }

    // Create new entry
    NewEntry.Target = Target;
    NewEntry.DamageDealt = 0.f;
    NewEntry.TargetMaxHP = Target.HealthMax;

    // Sanity check — if HealthMax is 0, this zed is invalid
    if (NewEntry.TargetMaxHP <= 0)
        return INDEX_NONE;

    Fractures.AddItem(NewEntry);
    return Fractures.Length - 1;
}

function CleanupDeadTargets()
{
    local int i;
    local array<SStressFracture> Cleaned;

    for (i = 0; i < Fractures.Length; ++i)
    {
        // Keep only alive, valid targets
        if (Fractures[i].Target != None && Fractures[i].Target.IsAliveAndWell())
            Cleaned.AddItem(Fractures[i]);
    }

    Fractures = Cleaned;
}

// ===================================================================
// SOUND — Uses ZTSoundManager pattern
// ===================================================================

function PlayShatterSound(name SoundID)
{
    local ZTPlayerController DKPC;
    local ZTMutator Mut;
    local SoundCue Sound;

    if (Player == None || Player.Controller == None)
        return;

    DKPC = ZTPlayerController(Player.Controller);
    if (DKPC == None)
        return;

    Mut = class'ZTSoundManager'.static.GetMutator(WorldInfo);
    if (Mut == None)
        return;

    Sound = class'ZTSoundManager'.static.GetSound(Mut, SoundID);
    if (Sound != None)
        DKPC.ClientPlayBuffSound(Sound);
}

defaultproperties
{
    RemoteRole=ROLE_None
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
    bHidden=True
    bCollideActors=False
    bBlockActors=False

    UpgradeLevel=1
    LastCleanupTime=0.0f
    CleanupInterval=3.0f    // Clean dead target refs every 3 seconds

    Name="Default__ZTUpgrade_Skill_ShatterPoint_Helper"
}
