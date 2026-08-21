// Wrapper for ZedternalReborn.WMUpgrade_Perk_Gunslinger
class ZTWrapper_Perk_Gunslinger extends WMUpgrade_Perk_Gunslinger config(ZedternalUnlimited);

var config float Cfg_MoveSpeed;
var config float Cfg_Damage;
var config float Cfg_HeadshotDamage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_MoveSpeed = 0.015000f;
		default.Cfg_Damage = 0.020000f;
		default.Cfg_HeadshotDamage = 0.020000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Gunslinger') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Gunslinger'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
	if (HitZoneIdx == HZI_HEAD)
		InDamage += Round(float(DefaultDamage) * default.Cfg_HeadshotDamage * upgLevel);
}

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	speedFactor += default.Cfg_MoveSpeed * upgLevel;
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_Gunslinger", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_Gunslinger", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Gunslinger"
	UpgradeDescription(0)="A mobile precision specialist who chains accurate shots with pistols."
	UpgradeDescription(1)="Per level: movement speed +1.5% (level 20: +30%)."
	UpgradeDescription(2)="Per level: headshot damage with all weapons +2% (level 20: +40%)."
	UpgradeDescription(3)="Per level: Gunslinger weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=2,maxValue=-1)
	PerkBonus(1)=(baseValue=0,incValue=2,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_Gunslinger"
}
