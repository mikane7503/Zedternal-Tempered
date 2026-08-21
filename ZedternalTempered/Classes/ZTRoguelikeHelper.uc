/**
 * ZTRoguelikeHelper
 * Base class for all Perk Unique roguelike passive helpers.
 * Spawned as ChildActor on the player's pawn when a PERK_X_ upgrade is selected.
 *
 * Subclasses override virtual functions to implement specific passive effects.
 * ZTPerk iterates ChildActors of this type to apply bonuses.
 *
 * Naming convention: PERK_X_BERSERKER -> ZTRoguelikeHelper_Berserker
 */
class ZTRoguelikeHelper extends Actor;

var KFPawn_Human OwnerPawn;
var KFPlayerController OwnerPC;

// ===================================================================
// INITIALIZATION
// ===================================================================

function Initialize(KFPawn_Human InPawn)
{
    OwnerPawn = InPawn;

    if (InPawn != None)
        OwnerPC = KFPlayerController(InPawn.Controller);

    `log("[DK_ROGUELIKE_HELPER]" @ Class.Name @ "initialized for" @ InPawn.PlayerReplicationInfo.PlayerName);
}

function Cleanup()
{
    OwnerPawn = None;
    OwnerPC = None;
}

// ===================================================================
// DAMAGE HOOKS — Override in subclasses
// Called from ZTPerk.ModifyDamageGiven() foreach iteration
// ===================================================================

/** Return additional damage multiplier to add (0.0 = no bonus) */
function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    return 0.0;
}

/** Called when a zed is killed by this player (from ModifyDamageGiven kill detection) */
function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    // Override in subclasses for kill tracking
}

// ===================================================================
// DAMAGE TAKEN HOOKS — Override in subclasses
// Called from ZTPerk.ModifyDamageTaken() foreach iteration
// ===================================================================

/** Modify incoming damage. Can reduce, cap, or prevent death. */
function ModifyIncomingDamage(out int InDamage, int DefaultDamage, KFPawn OwnerP, class<DamageType> DamageType)
{
    // Override in subclasses
}

// ===================================================================
// WAVE HOOKS — Override in subclasses
// Called from ZTPerk.WaveEnd() or GameInfo wave transitions
// ===================================================================

function OnWaveStart(int WaveNum)
{
    // Override in subclasses
}

function OnWaveEnd(int WaveNum)
{
    // Override in subclasses
}

// ===================================================================
// CLEANUP
// ===================================================================

event Destroyed()
{
    Cleanup();
    super.Destroyed();
}

defaultproperties
{
    RemoteRole=ROLE_None
    bHidden=true
    bCollideActors=false
    bBlockActors=false
    bProjTarget=false

    Name="Default__ZTRoguelikeHelper"
}
