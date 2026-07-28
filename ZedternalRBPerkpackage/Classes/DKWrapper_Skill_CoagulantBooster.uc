// Wrapper for ZedternalReborn.WMUpgrade_Skill_CoagulantBooster
class DKWrapper_Skill_CoagulantBooster extends WMUpgrade_Skill_CoagulantBooster
	config(ZedternalUnlimited);

var config array<float> Cfg_Resistance;
var config array<float> Cfg_MaxResistance;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Resistance[0] = 0.001f;
		default.Cfg_Resistance[1] = 0.0025f;
		default.Cfg_MaxResistance[0] = 0.1f;
		default.Cfg_MaxResistance[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (OwnerPawn != None)
		InDamage -= Round(float(DefaultDamage) * FMax(FMin(default.Cfg_Resistance[upgLevel - 1] * float(OwnerPawn.HealthMax - OwnerPawn.Health), default.Cfg_MaxResistance[upgLevel - 1]), 0.0f));
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_CoagulantBooster"
}
