// Wrapper for ZedternalReborn.WMUpgrade_Skill_RankThemUp
class ZTWrapper_Skill_RankThemUp extends WMUpgrade_Skill_RankThemUp config(ZedternalUnlimited);

var config array<float> Cfg_ExtraDamage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ExtraDamage[0] = 1.5f;
		default.Cfg_ExtraDamage[1] = 3.75f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_ExtraDamage.Length = 2;
		default.Cfg_ExtraDamage[0] = 1.500000f;
		default.Cfg_ExtraDamage[1] = 3.750000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_RankThemUp_Helper UPG;

	if (DamageType != None && MyKFPM != None && DamageInstigator != None && DamageInstigator.Pawn != None && MyKFPM.IsAliveAndWell() && !MyKFPM.bCheckingExtraHeadDamage && HitZoneIdx == HZI_HEAD)
	{
		UPG = GetHelper(DamageInstigator.Pawn);
		if (UPG != None)
		{
			if (UPG.HeadShot < UPG.MaxHeadShot)
				UPG.IncreaseCounter();
			else
			{
				UPG.EndStrike();
				InDamage += Round(float(DefaultDamage) * default.Cfg_ExtraDamage[upgLevel - 1]);
			}
		}
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_RankThemUp"
}
