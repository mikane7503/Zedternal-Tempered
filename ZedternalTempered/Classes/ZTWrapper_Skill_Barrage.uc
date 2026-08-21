// Wrapper for ZedternalReborn.WMUpgrade_Skill_Barrage
class ZTWrapper_Skill_Barrage extends WMUpgrade_Skill_Barrage config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int Cfg_RadiusSQ;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.25f;;
		default.Cfg_Damage[1] = 0.6f;;
		default.Cfg_RadiusSQ = 50000;;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Damage.Length = 2;
		default.Cfg_Damage[0] = 0.250000f;
		default.Cfg_Damage[1] = 0.600000f;
		default.Cfg_RadiusSQ = 50000;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_Barrage_Helper UPG;

	if (MyKFPM != None && DamageInstigator != None && DamageInstigator.Pawn != None && VSizeSQ(DamageInstigator.Pawn.Location - MyKFPM.Location) <= default.Cfg_RadiusSQ)
	{
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);
		if (InDamage > 5)
		{
			UPG = GetHelper(DamageInstigator.Pawn);
			if (UPG != None)
				UPG.CreateEffect();
		}
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Barrage"
}
