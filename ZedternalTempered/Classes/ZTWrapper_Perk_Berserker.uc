// Wrapper for ZedternalReborn.WMUpgrade_Perk_Berserker
class ZTWrapper_Perk_Berserker extends WMUpgrade_Perk_Berserker config(ZedternalUnlimited);

var config float Cfg_Damage;
var config float Cfg_AttackSpeed;
var config float Cfg_HealthFlat;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_Damage = 0.020000f;
		default.Cfg_AttackSpeed = 0.020000f;
		default.Cfg_HealthFlat = 5.000000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Berserker') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Berserker'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += Round(default.Cfg_HealthFlat * upgLevel);
}

static simulated function ModifyMeleeAttackSpeedPassive(out float durationFactor, int upgLevel)
{
	durationFactor = 1.0f / (1.0f / durationFactor + default.Cfg_AttackSpeed * upgLevel);
}

static simulated function ModifyRateOfFirePassive(out float rateOfFireFactor, int upgLevel)
{
	rateOfFireFactor = 1.0f / (1.0f / rateOfFireFactor + default.Cfg_AttackSpeed * upgLevel);
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_Berserker", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_Berserker", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Berserker"
	UpgradeDescription(0)="A frontline melee damage dealer and tank built around Berserker weapons."
	UpgradeDescription(1)="Per level: maximum health +5 (level 20: +100)."
	UpgradeDescription(2)="Per level: melee attack speed and rate of fire +2% (level 20: +40%)."
	UpgradeDescription(3)="Per level: Berserker weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=5,maxValue=-1)
	PerkBonus(1)=(baseValue=0,incValue=2,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_Berserker"
}
