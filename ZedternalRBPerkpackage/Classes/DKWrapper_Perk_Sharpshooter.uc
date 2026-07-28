// Wrapper for ZedternalReborn.WMUpgrade_Perk_Sharpshooter
class DKWrapper_Perk_Sharpshooter extends WMUpgrade_Perk_Sharpshooter
	config(ZedternalUnlimited);

var config float Cfg_DamageHead;
var config float Cfg_Recoil;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_DamageHead = 0.05f;
		default.Cfg_Recoil = 0.1f;
		default.Cfg_Damage = 0.05f;

		default.MODEVERSION = 1;
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
	local float Fb_Recoil;

	Fb_Recoil = default.Cfg_Recoil;
	if (Fb_Recoil == 0)
		Fb_Recoil = default.Recoil;
	recoilFactor -= recoilFactor * FMin(Fb_Recoil * upgLevel, 0.8f);
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Sharpshooter"
}
