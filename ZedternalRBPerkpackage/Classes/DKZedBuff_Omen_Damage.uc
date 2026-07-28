class DKZedBuff_Omen_Damage extends WMZedBuff;

var float Damage;

static function ModifyZedDamageMod(out float PerZedDamageMod, KFPawn_Monster P, float GameDifficulty)
{
    PerZedDamageMod += default.Damage;
}

defaultproperties
{
    Damage=0.05f

    bShouldLocalize=False
    BuffDescription="Omen: Zeds deal +5% damage"
    BuffIcon=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_ZedBuff_Omen_Damage'

    Name="Default__DKZedBuff_Omen_Damage"
}
