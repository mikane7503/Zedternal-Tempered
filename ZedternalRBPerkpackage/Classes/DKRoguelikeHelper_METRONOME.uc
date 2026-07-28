/**
 * DKRoguelikeHelper_METRONOME — "Perfect Tempo"
 * Sync kills (killing during correct Metronome phase) grant stacking +3%
 * all-damage buff for 15s. Max 10 stacks = +30%.
 * NOTE: Sync kill detection requires checking Metronome helper state.
 * For now, all kills grant stacks — refine later with Metronome phase check.
 */
class DKRoguelikeHelper_METRONOME extends DKRoguelikeHelper;

var int Stacks;
var float StackExpireTime;

const MAX_STACKS = 10;
const DAMAGE_PER_STACK = 0.03;
const STACK_DURATION = 15.0;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (Stacks > 0 && OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds < StackExpireTime)
        return DAMAGE_PER_STACK * float(Stacks);

    // Expired — reset
    if (Stacks > 0 && OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds >= StackExpireTime)
        Stacks = 0;

    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    // TODO: Check if this was during the correct Metronome phase via helper
    // For now, every kill counts as a "sync kill" for testing
    if (Stacks < MAX_STACKS)
        Stacks++;

    if (OwnerPawn != None)
        StackExpireTime = OwnerPawn.WorldInfo.TimeSeconds + STACK_DURATION;
}

defaultproperties
{
    Stacks=0
    StackExpireTime=0.0
    Name="Default__DKRoguelikeHelper_METRONOME"
}
