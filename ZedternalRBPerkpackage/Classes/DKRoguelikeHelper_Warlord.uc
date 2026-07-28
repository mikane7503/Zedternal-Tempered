/**
 * DKRoguelikeHelper_Warlord — "Iron Curtain"
 * Every 20 kills grants +5 permanent armor (no cap, persists through waves).
 * At 200+ total armor, gain an additional +15% damage resistance.
 */
class DKRoguelikeHelper_Warlord extends DKRoguelikeHelper;

var int TotalKills;
var int MilestonesReached;
var int BonusArmor;

const KILLS_PER_MILESTONE = 20;
const ARMOR_PER_MILESTONE = 5;
const DR_ARMOR_THRESHOLD = 200;
const DR_BONUS = 0.15;

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    local int NewMilestones;

    TotalKills++;
    NewMilestones = TotalKills / KILLS_PER_MILESTONE;

    if (NewMilestones > MilestonesReached)
    {
        BonusArmor += ARMOR_PER_MILESTONE * (NewMilestones - MilestonesReached);
        MilestonesReached = NewMilestones;

        // OwnerPawn is KFPawn_Human — MaxArmor accessible directly
        if (OwnerPawn != None)
        {
            OwnerPawn.MaxArmor += ARMOR_PER_MILESTONE;
            `log("[DK_RL_WARLORD] Iron Curtain: +" $ ARMOR_PER_MILESTONE $ " armor (total bonus:" @ BonusArmor $ ")");
        }
    }
}

function ModifyIncomingDamage(out int InDamage, int DefaultDamage, KFPawn OwnerP, class<DamageType> DamageType)
{
    // OwnerP param is KFPawn — use our OwnerPawn (KFPawn_Human) for MaxArmor
    if (OwnerPawn != None && OwnerPawn.MaxArmor >= DR_ARMOR_THRESHOLD)
    {
        InDamage -= Round(float(DefaultDamage) * DR_BONUS);
        if (InDamage < 0)
            InDamage = 0;
    }
}

defaultproperties
{
    TotalKills=0
    MilestonesReached=0
    BonusArmor=0
    Name="Default__DKRoguelikeHelper_Warlord"
}
