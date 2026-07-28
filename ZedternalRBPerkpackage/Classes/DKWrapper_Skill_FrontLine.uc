// Wrapper for ZedternalReborn.WMUpgrade_Skill_FrontLine
class DKWrapper_Skill_FrontLine extends WMUpgrade_Skill_FrontLine
	config(ZedternalUnlimited);

var config array<float> Cfg_OtherResistance;
var config array<float> Cfg_SelfExplosiveResistance;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_OtherResistance[0] = 0.05f;
		default.Cfg_OtherResistance[1] = 0.1f;
		default.Cfg_SelfExplosiveResistance[0] = 0.35f;
		default.Cfg_SelfExplosiveResistance[1] = 0.75f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Explosive') && KFPlayerController(InstigatedBy) != None)
		InDamage -= DefaultDamage * default.Cfg_SelfExplosiveResistance[upgLevel - 1];
	else
		InDamage -= DefaultDamage * default.Cfg_OtherResistance[upgLevel - 1];
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_FrontLine"
}
