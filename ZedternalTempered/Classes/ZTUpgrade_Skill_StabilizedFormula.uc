// Jekyll skill - Stabilized Formula: extra grenades and larger spare ammo reserves.
// (Grenades/ammo only matter in gun-form, so these need no explicit form gate.)
class ZTUpgrade_Skill_StabilizedFormula extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<int> Grenades;
var config array<float> SpareAmmo;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Grenades[0] = 1;     default.Grenades[1] = 2;
		default.SpareAmmo[0] = 0.10f; default.SpareAmmo[1] = 0.20f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifySpareGrenadeAmount(out int SpareGrenade, int DefaultSpareGrenade, int upgLevel)
{
	SpareGrenade += default.Grenades[upgLevel - 1];
}

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=False)
{
	InSpareAmmo += Round(float(DefaultSpareAmmo) * default.SpareAmmo[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_StabilizedFormula"
	UpgradeName="Stabilized Formula"
	upgradeDescription(0)="<font color=\"#77d914\">+1</font> grenade and <font color=\"#77d914\">+10%</font> spare ammo capacity."
	upgradeDescription(1)="<font color=\"#77d914\">+2</font> grenades and <font color=\"#77d914\">+20%</font> spare ammo capacity."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_StabilizedFormula'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_StabilizedFormula_Deluxe'
	Name="Default__ZTUpgrade_Skill_StabilizedFormula"
}
