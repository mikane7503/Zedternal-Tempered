// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_BloodthirstyArmor
class DKWrapper_Skill_BloodthirstyArmor extends ZRUpgrade_Skill_BloodthirstyArmor
	config(ZedternalUnlimited);

var config array<int> Cfg_ArmorOnKillLarge;
var config array<int> Cfg_Armor;
var config array<int> Cfg_ArmorOnKillSmall;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ArmorOnKillLarge[0] = 5;
		default.Cfg_ArmorOnKillLarge[1] = 10;
		default.Cfg_Armor[0] = 1;
		default.Cfg_Armor[1] = 3;
		default.Cfg_ArmorOnKillSmall[0] = 1;
		default.Cfg_ArmorOnKillSmall[1] = 2;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZRUpgrade_Skill_BloodthirstyArmor_Helper UPG;

	if (DamageInstigator.Pawn != None)
	{
		UPG = GetHelper(DamageInstigator.Pawn);
		if (UPG != None)
			// On Hit give Armor
			//UPG.GiveArmor(default.Cfg_Armor[upgLevel - 1]);

			// On Small ZED Kill
			if (MyKFPM != None && MyKFPM.IsAliveAndWell() && (MyKFPM.Health - InDamage) <= 0 && DamageInstigator != None && DamageInstigator.Pawn != None)
			{
				UPG.GiveArmor(default.Cfg_ArmorOnKillSmall[upglevel -1]);
				DamageInstigator.MyGFxHUD.ShowNonCriticalMessage("+" $ default.Cfg_ArmorOnKillSmall[upglevel -1] $ " Armor");
			}
			// On Big ZED Kill
			if (MyKFPM != None && MyKFPM.bLargeZed && MyKFPM.IsAliveAndWell() && (MyKFPM.Health - InDamage) <= 0 && DamageInstigator != None && DamageInstigator.Pawn != None)
			{
				UPG.GiveArmor(default.Cfg_ArmorOnKillLarge[upglevel -1]);
				DamageInstigator.MyGFxHUD.ShowNonCriticalMessage("+" $ default.Cfg_ArmorOnKillLarge[upglevel -1] $ " Armor");
			}
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_BloodthirstyArmor"
}
