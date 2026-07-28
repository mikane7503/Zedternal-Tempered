// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_Antibodies
class DKWrapper_Skill_Antibodies extends ZRUpgrade_Skill_Antibodies
	config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.20f;
		default.Cfg_Damage[1] = 0.40f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (DamageType != None && (ClassIsChildOf(Damagetype, class'KFDT_Toxic')))
		InDamage -= Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Antibodies"
}
