class ZTZedBuff_Omen_Speed extends WMZedBuff;

var float Speed, SprintChance;

static function ModifyZedSpeedMod(out float SpeedMod, KFPawn_Monster P, float GameDifficulty)
{
    SpeedMod += default.Speed;
}

static function ModifyZedSprintChanceMod(out float SprintChanceMod, KFPawn_Monster P, float GameDifficulty)
{
    SprintChanceMod += default.SprintChance;
}

defaultproperties
{
    Speed=0.03f
    SprintChance=0.1f

    bShouldLocalize=False
    BuffDescription="Omen: Zeds gain +3% speed"
    BuffIcon=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_ZedBuff_Omen_Speed'

    Name="Default__ZTZedBuff_Omen_Speed"
}
