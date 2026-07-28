// Wrapper for ZedternalReborn.WMUpgrade_Perk_Demolitionist
class DKWrapper_Perk_Demolitionist extends WMUpgrade_Perk_Demolitionist
	config(ZedternalUnlimited);

var config float Cfg_LZDamage;
var config float Cfg_Damage;
var config float Cfg_GrenadeDamage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_LZDamage = 0.05f;
		default.Cfg_Damage = 0.05f;
		default.Cfg_GrenadeDamage = 0.15f;

		default.MODEVERSION = 1;
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

defaultproperties
{
	Name="Default__DKWrapper_Perk_Demolitionist"
}
