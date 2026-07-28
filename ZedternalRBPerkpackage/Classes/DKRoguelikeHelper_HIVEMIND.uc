/** "Neural Network" - Allies in 15m: +10% reload/dmg. Self +5%/ally (max 25%). */
class DKRoguelikeHelper_HIVEMIND extends DKRoguelikeHelper;

const BONUS_PER_ALLY = 0.05;
const MAX_ALLIES = 5;
const ALLY_RANGE = 1500.0;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    local int AllyCount;
    local KFPawn_Human KFPH;

    if (OwnerPawn == None) return 0.0;

    foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Human', KFPH)
    {
        if (KFPH != OwnerPawn && KFPH.IsAliveAndWell() && VSize(KFPH.Location - OwnerPawn.Location) <= ALLY_RANGE)
        {
            AllyCount++;
            if (AllyCount >= MAX_ALLIES) break;
        }
    }

    return BONUS_PER_ALLY * float(AllyCount);
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_HIVEMIND"
}
