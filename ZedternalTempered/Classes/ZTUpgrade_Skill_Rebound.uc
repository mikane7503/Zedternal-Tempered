// Rebound - returned Goalkeeper projectiles hit harder. Pure hook, inert without the perk's DT.
class ZTUpgrade_Skill_Rebound extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> DamageBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DamageBonus[0] = 0.25f;
		default.DamageBonus[1] = 0.50f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (DamageType == None || !ClassIsChildOf(DamageType, class'ZTDT_Goalkeeper_Return'))
		return;

	InDamage += Round(float(DefaultDamage) * default.DamageBonus[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Rebound"

	UpgradeName="Rebound"
	upgradeDescription(0)="<font color=\"#15d7fa\">Goalkeeper only:</font> returned projectiles deal <font color=\"#ff3399\">+25% damage</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Goalkeeper only:</font> returned projectiles deal <font color=\"#ff3399\">+50% damage</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Rebound'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Rebound_Deluxe'
	Name="Default__ZTUpgrade_Skill_Rebound"
}
