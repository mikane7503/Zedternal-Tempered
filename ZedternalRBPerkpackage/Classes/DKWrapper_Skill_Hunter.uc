// Wrapper for ZedternalReborn.WMUpgrade_Skill_Hunter
class DKWrapper_Skill_Hunter extends WMUpgrade_Skill_Hunter
	config(ZedternalUnlimited);

var config array<int> Cfg_Vampire;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Vampire[0] = 15;
		default.Cfg_Vampire[1] = 40;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (MyKFPM != None && (MyKFPM.static.IsLargeZed() || MyKFPM.static.IsABoss()) && MyKFPM.IsAliveAndWell() && (MyKFPM.Health - InDamage) <= 0 && DamageInstigator != None && DamageInstigator.Pawn != None)
		DamageInstigator.Pawn.HealDamage(default.Cfg_Vampire[upgLevel - 1], DamageInstigator, class'KFDT_Healing');
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Hunter"
}
