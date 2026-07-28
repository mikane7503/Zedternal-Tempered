// Wrapper for ZedternalReborn.WMUpgrade_Perk_Commando
class DKWrapper_Perk_Commando extends WMUpgrade_Perk_Commando
	config(ZedternalUnlimited);

var config float Cfg_Damage;
var config float Cfg_ReloadRate;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage = 0.05f;
		default.Cfg_ReloadRate = 0.15f;

		default.MODEVERSION = 1;
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
	local float Fb_ReloadRate;

	Fb_ReloadRate = default.Cfg_ReloadRate;
	if (Fb_ReloadRate == 0)
		Fb_ReloadRate = default.ReloadRate;
	reloadRateFactor = 1.0f / (1.0f / reloadRateFactor + Fb_ReloadRate * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Commando"
}
