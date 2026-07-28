// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_GunNut
class DKWrapper_Skill_GunNut extends ZRUpgrade_Skill_GunNut
	config(ZedternalUnlimited);

var config float Cfg_ReloadRateDeluxe;
var config array<float> Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ReloadRateDeluxe = 0.3f;
		default.Cfg_Damage[0] = 0.10f;
		default.Cfg_Damage[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Commando') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Commando') || IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Demolitionist') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Demolitionist') || IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Gunslinger') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Gunslinger') || IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Sharpshooter') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Sharpshooter') || IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Support') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Support') || IsWeaponOnSpecificPerk(MyKFW, class'KFGame.KFPerk_Swat') || IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Swat'))
		InDamage += Round(float(DefaultDamage) * default.Cfg_Damage[upgLevel]);
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
	local float Fb_ReloadRateDeluxe;

	Fb_ReloadRateDeluxe = default.Cfg_ReloadRateDeluxe;
	if (Fb_ReloadRateDeluxe == 0)
		Fb_ReloadRateDeluxe = default.ReloadRateDeluxe;
	if (upgLevel > 1)
		reloadRateFactor = 1.0f / (1.0f / reloadRateFactor + Fb_ReloadRateDeluxe);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_GunNut"
}
