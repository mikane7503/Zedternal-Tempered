// Wrapper for ZedternalReborn.WMUpgrade_Perk_Sharpshooter
class ZTWrapper_Perk_Sharpshooter extends WMUpgrade_Perk_Sharpshooter config(ZedternalUnlimited);

var config float Cfg_DamageHead;
var config float Cfg_Recoil;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_DamageHead = 0.020000f;
		default.Cfg_Recoil = 0.020000f;
		default.Cfg_Damage = 0.020000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Sharpshooter') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Sharpshooter'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);

	if (HitZoneIdx == HZI_HEAD)
		InDamage += Round(float(DefaultDamage) * default.Cfg_DamageHead * upgLevel);
}

static simulated function ModifyRecoilPassive(out float recoilFactor, int upgLevel)
{
	recoilFactor -= recoilFactor * FMin(default.Cfg_Recoil * upgLevel, 0.8f);
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_Sharpshooter", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_Sharpshooter", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Sharpshooter"
	UpgradeDescription(0)="A long-range precision specialist who removes priority targets and weak points."
	UpgradeDescription(1)="Per level: recoil with all weapons -2% (maximum -80%)."
	UpgradeDescription(2)="Per level: headshot damage with all weapons +2% (level 20: +40%)."
	UpgradeDescription(3)="Per level: Sharpshooter weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=2,maxValue=80)
	PerkBonus(1)=(baseValue=0,incValue=2,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_Sharpshooter"
}
