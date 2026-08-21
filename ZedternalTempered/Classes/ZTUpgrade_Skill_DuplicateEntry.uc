// Duplicate Entry - universal glitch: duplicated reserves. Spare ammo + grenades.
class ZTUpgrade_Skill_DuplicateEntry extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> SpareBonus;
var config array<int> GrenadeBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.SpareBonus[0] = 0.20f;
		default.SpareBonus[1] = 0.35f;
		default.GrenadeBonus[0] = 1;
		default.GrenadeBonus[1] = 2;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifySpareAmmoAmountPassive(out float spareAmmoFactor, int upgLevel)
{
	spareAmmoFactor += default.SpareBonus[upgLevel - 1];
}

static simulated function ModifySpareGrenadeAmount(out int SpareGrenade, int DefaultSpareGrenade, int upgLevel)
{
	SpareGrenade += default.GrenadeBonus[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_DuplicateEntry"

	UpgradeName="Duplicate Entry"
	upgradeDescription(0)="<font color=\"#00ff00\">Spare ammo +20%</font> and <font color=\"#00ffff\">+1 Grenade</font>."
	upgradeDescription(1)="<font color=\"#00ff00\">Spare ammo +35%</font> and <font color=\"#00ffff\">+2 Grenades</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_DuplicateEntry'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_DuplicateEntry_Deluxe'
	Name="Default__ZTUpgrade_Skill_DuplicateEntry"
}
