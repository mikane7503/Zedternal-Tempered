// Wrapper for ZedternalReborn.WMUpgrade_Skill_Tank
class DKWrapper_Skill_Tank extends WMUpgrade_Skill_Tank
	config(ZedternalUnlimited);

var config array<float> Cfg_Resistance;
var config array<float> Cfg_Critical;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Resistance[0] = 0.2f;
		default.Cfg_Resistance[1] = 0.3f;
		default.Cfg_Critical[0] = 0.9f;
		default.Cfg_Critical[1] = 0.7f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_Tank_Helper UPG;

	if (OwnerPawn != None && OwnerPawn.Health >= int(float(OwnerPawn.HealthMax) * default.Cfg_Critical[upgLevel - 1]))
	{
		InDamage -= Max(1, Round(float(DefaultDamage) * default.Cfg_Resistance[upgLevel - 1]));

		UPG = GetHelper(OwnerPawn);
		if (UPG != None)
			UPG.ActiveEffect();
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Tank"
}
