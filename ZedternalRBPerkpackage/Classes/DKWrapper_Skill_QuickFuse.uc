// Wrapper for ZedternalReborn.WMUpgrade_Skill_QuickFuse
class DKWrapper_Skill_QuickFuse extends WMUpgrade_Skill_QuickFuse
	config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.2f;
		default.Cfg_Damage[1] = 0.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType != None && static.IsGrenadeDTAdvance(DamageType, DamageInstigator))
		InDamage += DefaultDamage * default.Cfg_Damage[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_QuickFuse"
}
