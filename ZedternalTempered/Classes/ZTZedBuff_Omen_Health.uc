class ZTZedBuff_Omen_Health extends WMZedBuff;

var float Health, LargeZedHealth, HeadHealth;

static function ModifyZedHealthMod(out float HealthMod, KFPawn_Monster P, float GameDifficulty, byte NumLivingPlayers)
{
    if (P.static.IsLargeZed() || P.static.IsABoss())
        HealthMod += default.LargeZedHealth;
    else
        HealthMod += default.Health;
}

static function ModifyZedHeadHealthMod(out float HeadHealthMod, KFPawn_Monster P, float GameDifficulty, byte NumLivingPlayers)
{
    HeadHealthMod += default.HeadHealth;
}

defaultproperties
{
    Health=0.05f
    LargeZedHealth=0.04f
    HeadHealth=0.05f

    bShouldLocalize=False
    BuffDescription="Omen: Zeds gain +5% health"
    BuffIcon=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_ZedBuff_Omen_Health'

    Name="Default__ZTZedBuff_Omen_Health"
}
