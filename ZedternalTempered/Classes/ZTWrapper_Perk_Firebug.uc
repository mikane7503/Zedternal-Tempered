// Wrapper for ZedternalReborn.WMUpgrade_Perk_Firebug
class ZTWrapper_Perk_Firebug extends WMUpgrade_Perk_Firebug config(ZedternalUnlimited);

var config float Cfg_Damage;
var config float Cfg_Defense;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_Damage = 0.020000f;
		default.Cfg_Defense = 0.010000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Firebug') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Firebug'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Fire') || ClassIsChildOf(DamageType, class'KFDT_Explosive') || ClassIsChildOf(DamageType, class'KFDT_Toxic') || ClassIsChildOf(DamageType, class'KFDT_Sonic'))
		InDamage -= Round(float(DefaultDamage) * FMin(default.Cfg_Defense * upgLevel, 0.4f));
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_Firebug", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_Firebug", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Firebug"
	UpgradeDescription(0)="A flame-weapon specialist who controls crowds and survives hazardous zones."
	UpgradeDescription(1)="Per level: fire, explosive, toxic and sonic resistance +1% (level 20: +20%)."
	UpgradeDescription(2)="Per level: Firebug weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=3
	PerkBonus(0)=(baseValue=0,incValue=1,maxValue=40)
	PerkBonus(1)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_Firebug"
}
