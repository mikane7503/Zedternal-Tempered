class ZTZedBuff_Omen_HardAttack extends WMZedBuff;

var float HardAttackIncrease;

static function ModifyHardAttackChanceMod(out float HardAttackChanceMod)
{
    HardAttackChanceMod += default.HardAttackIncrease;
}

defaultproperties
{
    HardAttackIncrease=0.15f

    bShouldLocalize=False
    BuffDescription="Omen: Zeds use heavy attacks more often"
    BuffIcon=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_ZedBuff_Omen_HardAttack'

    Name="Default__ZTZedBuff_Omen_HardAttack"
}
