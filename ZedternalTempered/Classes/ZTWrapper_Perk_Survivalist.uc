// Wrapper for ZedternalReborn.WMUpgrade_Perk_Survivalist
class ZTWrapper_Perk_Survivalist extends WMUpgrade_Perk_Survivalist config(ZedternalUnlimited);

var config float Cfg_SpareAmmo;
var config float Cfg_Damage;
var config int Cfg_WeightPerLevel;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_SpareAmmo = 0.050000f;
		default.Cfg_Damage = 0.020000f;
		default.Cfg_WeightPerLevel = 1;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
	damageFactor += default.Cfg_Damage * upgLevel;
}

static function ApplyWeightLimits(out int InWeightLimit, int DefaultWeightLimit, int upgLevel)
{
	InWeightLimit += default.Cfg_WeightPerLevel * upgLevel;
}

static simulated function ModifySpareAmmoAmountPassive(out float spareAmmoFactor, int upgLevel)
{
	spareAmmoFactor += default.Cfg_SpareAmmo * upgLevel;
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_Survivalist", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_Survivalist", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Survivalist"
	UpgradeDescription(0)="A flexible all-weapon specialist who secures resources and carrying capacity."
	UpgradeDescription(1)="Per level: carry weight +1 (level 20: +20)."
	UpgradeDescription(2)="Per level: spare ammunition +5% (level 20: +100%)."
	UpgradeDescription(3)="Per level: damage with all weapons +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=1,maxValue=-1)
	PerkBonus(1)=(baseValue=0,incValue=5,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_Survivalist"
}
