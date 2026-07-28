// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_ShockAbsorbers
class DKWrapper_Skill_ShockAbsorbers extends ZRUpgrade_Skill_ShockAbsorbers
	config(ZedternalUnlimited);

var config array<float> Cfg_DamageResistance;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_DamageResistance[0] = 0.3f;
		default.Cfg_DamageResistance[1] = 0.6f;
		default.Cfg_Damage[0] = 0.15f;
		default.Cfg_Damage[1] = 0.4f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageInstigator != None && WMPawn_Human(DamageInstigator.Pawn) != None && WMPawn_Human(DamageInstigator.Pawn).ZedternalArmor > 0)
		InDamage += DefaultDamage * default.Cfg_Damage[upgLevel - 1];
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Falling') && OwnerPawn != None && WMPawn_Human(OwnerPawn).ZedternalArmor > 0)
		InDamage -= Round(float(DefaultDamage) * default.Cfg_DamageResistance[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_ShockAbsorbers"
}
