/** "Nuclear Option" - Every 10th explosion deals 3x dmg in 2x radius. */
class ZTRoguelikeHelper_DEMOLITIONIST extends ZTRoguelikeHelper;

var int ExplosionCount;
const EXPLOSIONS_PER_PROC = 10;
const DAMAGE_MULT = 2.00;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Explosive'))
    {
        ExplosionCount++;
        if (ExplosionCount >= EXPLOSIONS_PER_PROC)
        {
            ExplosionCount = 0;
            `log("[DK_RL_DEMO] Nuclear Option: 3x explosion!");
            return DAMAGE_MULT;
        }
    }
    return 0.0;
}

defaultproperties
{
    ExplosionCount=0
    Name="Default__ZTRoguelikeHelper_DEMOLITIONIST"
}
