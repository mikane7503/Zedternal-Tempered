// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_Juggernaut
class DKWrapper_Skill_Juggernaut extends ZRUpgrade_Skill_Juggernaut
	config(ZedternalUnlimited);

var config array<float> Cfg_Resistance;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Resistance[0] = 0.1f;
		default.Cfg_Resistance[1] = 0.2f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (KFPawn_Human(OwnerPawn) != None && KFPawn_Human(OwnerPawn).Armor > 0)
	{
		InDamage -= Max(1, Round(float(DefaultDamage) * default.Cfg_Resistance[upgLevel - 1]));
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Juggernaut"
}
