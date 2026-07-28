// Wrapper for ZedternalReborn.WMUpgrade_Skill_Tenacity
class DKWrapper_Skill_Tenacity extends WMUpgrade_Skill_Tenacity
	config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.15f;
		default.Cfg_Damage[1] = 0.4f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_Tenacity_Helper UPG;

	if (OwnerPawn != None)
	{
		UPG = GetHelper(OwnerPawn);
		if (UPG != None && UPG.bActive)
			InDamage -= Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Tenacity"
}
