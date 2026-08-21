// Wrapper for ZedternalReborn.WMUpgrade_Perk_SWAT
class ZTWrapper_Perk_SWAT extends WMUpgrade_Perk_SWAT config(ZedternalUnlimited);

var config float Cfg_Armor;
var config float Cfg_Damage;
var config float Cfg_MagSize;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_Armor = 0.050000f;
		default.Cfg_Damage = 0.020000f;
		default.Cfg_MagSize = 0.050000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Swat') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Swat'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	MaxArmor += Round(float(DefaultArmor) * FMin(default.Cfg_Armor * upgLevel, 1.0f));
}

static simulated function ModifyMagSizeAndNumberPassive(out float magazineCapacityFactor, int upgLevel)
{
	magazineCapacityFactor += default.Cfg_MagSize * upgLevel;
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_SWAT", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_SWAT", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="SWAT"
	UpgradeDescription(0)="A close-range SMG specialist who maintains the frontline with heavy armor."
	UpgradeDescription(1)="Per level: maximum armor +5% (maximum +100%)."
	UpgradeDescription(2)="Per level: magazine capacity +5% (level 20: +100%)."
	UpgradeDescription(3)="Per level: SWAT weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=5,maxValue=100)
	PerkBonus(1)=(baseValue=0,incValue=5,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_SWAT"
}
