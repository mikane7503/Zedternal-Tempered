// Wrapper for ZedternalReborn.WMUpgrade_Perk_Support
class ZTWrapper_Perk_Support extends WMUpgrade_Perk_Support config(ZedternalUnlimited);

var config float Cfg_StoppingPower;
var config float Cfg_Damage;
var config float Cfg_Penetration;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_StoppingPower = 0.020000f;
		default.Cfg_Damage = 0.020000f;
		default.Cfg_Penetration = 0.100000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Support') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Support'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyStumblePowerPassive(out float stumblePowerFactor, int upgLevel)
{
	stumblePowerFactor += default.Cfg_StoppingPower * upgLevel;
}

static function ModifyKnockdownPowerPassive(out float knockdownPowerFactor, int upgLevel)
{
	knockdownPowerFactor += default.Cfg_StoppingPower * upgLevel;
}

static simulated function ModifyPenetrationPassive(out float penetrationFactor, int upgLevel)
{
	penetrationFactor += default.Cfg_Penetration * upgLevel;
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_Support", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_Support", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Support"
	UpgradeDescription(0)="A shotgun specialist who holds the line and supports the squad with supplies."
	UpgradeDescription(1)="Per level: stumble and knockdown power +2% (level 20: +40%)."
	UpgradeDescription(2)="Per level: penetration +10% (level 20: +200%)."
	UpgradeDescription(3)="Per level: Support weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=2,maxValue=-1)
	PerkBonus(1)=(baseValue=0,incValue=10,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_Support"
}
