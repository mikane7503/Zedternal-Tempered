// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_IcyArmor
class DKWrapper_Skill_IcyArmor extends ZRUpgrade_Skill_IcyArmor
	config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.15f;
		default.Cfg_Damage[1] = 0.30f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (OwnerPawn != None && VSizeSq(OwnerPawn.Velocity) <= 0)
		InDamage -= Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_IcyArmor"
}
