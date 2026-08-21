// Wrapper for ZedternalReborn.WMUpgrade_Perk_FieldMedic
class ZTWrapper_Perk_FieldMedic extends WMUpgrade_Perk_FieldMedic config(ZedternalUnlimited);

var config float Cfg_HealRate;
var config float Cfg_Health;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.Cfg_HealRate = 0.050000f;
		default.Cfg_Health = 2.000000f;
		default.Cfg_Damage = 0.020000f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_FieldMedic') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_FieldMedic'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage * upgLevel);
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += Round(default.Cfg_Health * upgLevel);
}

static simulated function ModifyHealerRechargeTime(out float InRechargeTime, float DefaultRechargeTime, int upgLevel)
{
	InRechargeTime = DefaultRechargeTime / (DefaultRechargeTime / InRechargeTime + default.Cfg_HealRate * upgLevel);
}

static function string GetUpgradeName()
{
	return class'ZTOriginalPerkLocalization'.static.GetName("ZTWrapper_Perk_FieldMedic", default.UpgradeName);
}

static function string GetUpgradeDescription(byte Line)
{
	local string Fallback;
	if (Line < default.UpgradeDescription.Length) Fallback = default.UpgradeDescription[Line];
	return class'ZTOriginalPerkLocalization'.static.GetDescription("ZTWrapper_Perk_FieldMedic", Line, Fallback);
}

defaultproperties
{
	bShouldLocalize=True
	UpgradeName="Field Medic"
	UpgradeDescription(0)="A combat-support specialist who keeps allies alive with healing weapons."
	UpgradeDescription(1)="Per level: maximum health +2 (level 20: +40)."
	UpgradeDescription(2)="Per level: syringe and healing-dart recharge speed +5% (level 20: +100%)."
	UpgradeDescription(3)="Per level: Field Medic weapon damage +2% (level 20: +40%)."
	LocalizeDescriptionLineCount=4
	PerkBonus(0)=(baseValue=0,incValue=2,maxValue=-1)
	PerkBonus(1)=(baseValue=0,incValue=5,maxValue=-1)
	PerkBonus(2)=(baseValue=0,incValue=2,maxValue=-1)
	Name="Default__ZTWrapper_Perk_FieldMedic"
}
