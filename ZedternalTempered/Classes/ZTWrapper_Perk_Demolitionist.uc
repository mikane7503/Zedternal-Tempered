// Wrapper for ZedternalReborn.WMUpgrade_Perk_Demolitionist
class ZTWrapper_Perk_Demolitionist extends WMUpgrade_Perk_Demolitionist config(ZedternalUnlimited);

var config float Cfg_LZDamage;
var config float Cfg_Damage;
var config float Cfg_GrenadeDamage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_LZDamage = 0.030000f;
		default.Cfg_Damage = 0.020000f;
		default.Cfg_GrenadeDamage = 0.050000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Demolitionist') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Demolitionist'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);

	if (DamageType != None && static.IsGrenadeDTAdvance(DamageType, DamageInstigator))
		InDamage += Round(float(DefaultDamage) * default.Cfg_GrenadeDamage * upgLevel);

	if (MyKFPM != None && (MyKFPM.static.IsLargeZed() || MyKFPM.static.IsABoss()))
		InDamage += Round(float(DefaultDamage) * default.Cfg_LZDamage * upgLevel);
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_Demolitionist", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_Demolitionist", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Demolitionist"
	UpgradeDescription(0)="An explosive-area specialist built to eliminate large Zeds and bosses."
	UpgradeDescription(1)="Per level: grenade damage +5% (level 20: +100%)."
	UpgradeDescription(2)="Per level: damage to large Zeds and bosses +3% (level 20: +60%)."
	UpgradeDescription(3)="Per level: Demolitionist weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=5,maxValue=-1)
	PerkBonus(1)=(baseValue=0,incValue=3,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_Demolitionist"
}
