// Wrapper for ZedternalReborn.WMUpgrade_Skill_GunMachine
class DKWrapper_Skill_GunMachine extends WMUpgrade_Skill_GunMachine
	config(ZedternalUnlimited);

var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage[0] = 0.25f;
		default.Cfg_Damage[1] = 0.6f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local WMUpgrade_Skill_GunMachine_Helper UPG;

	if (DamageInstigator.Pawn != None && MyKFPM != None)
	{
		UPG = GetHelper(DamageInstigator.Pawn);
		if (UPG != None)
		{
			if (UPG.bActive)
				InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel - 1]);

			if ((MyKFPM.Health - InDamage) <= 0)
				UPG.SetActive();
		}
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_GunMachine"
}
