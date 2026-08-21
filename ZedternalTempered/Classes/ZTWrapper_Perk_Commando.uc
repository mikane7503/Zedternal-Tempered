// Wrapper for ZedternalReborn.WMUpgrade_Perk_Commando
class ZTWrapper_Perk_Commando extends WMUpgrade_Perk_Commando config(ZedternalUnlimited);

var config float Cfg_Damage;
var config float Cfg_ReloadRate;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_Damage = 0.020000f;
		default.Cfg_ReloadRate = 0.015000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Commando') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Commando'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
	reloadRateFactor = 1.0f / (1.0f / reloadRateFactor + default.Cfg_ReloadRate * upgLevel);
}

static simulated function GetZedTimeExtension(out float InExtension, float DefaultExtension, int upgLevel)
{
	InExtension += float(Min(upgLevel, 10));
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_Commando", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_Commando", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Commando"
	UpgradeDescription(0)="A mid-range assault-rifle specialist who controls ZED Time."
	UpgradeDescription(1)="Per level: ZED Time extension +1 second (maximum +10 seconds)."
	UpgradeDescription(2)="Per level: reload speed +1.5% (level 20: +30%)."
	UpgradeDescription(3)="Per level: Commando weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=1,maxValue=10)
	PerkBonus(1)=(baseValue=0,incValue=2,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_Commando"
}
