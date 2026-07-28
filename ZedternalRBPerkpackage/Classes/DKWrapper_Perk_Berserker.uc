// Wrapper for ZedternalReborn.WMUpgrade_Perk_Berserker
class DKWrapper_Perk_Berserker extends WMUpgrade_Perk_Berserker
	config(ZedternalUnlimited);

var config float Cfg_Damage;
var config float Cfg_Defense;
var config float Cfg_AttackSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Damage = 0.05f;
		default.Cfg_Defense = 0.03f;
		default.Cfg_AttackSpeed = 0.05f;

		default.MODEVERSION = 1;
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

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Bludgeon') || ClassIsChildOf(DamageType, class'KFDT_Piercing') || ClassIsChildOf(DamageType, class'KFDT_Slashing'))
		InDamage -= Round(float(DefaultDamage) * FMin(default.Cfg_Defense * upgLevel, 0.30f));
}

static simulated function ModifyMeleeAttackSpeedPassive(out float durationFactor, int upgLevel)
{
	local float Fb_AttackSpeed;

	Fb_AttackSpeed = default.Cfg_AttackSpeed;
	if (Fb_AttackSpeed == 0)
		Fb_AttackSpeed = default.AttackSpeed;
	durationFactor = 1.0f / (1.0f / durationFactor + Fb_AttackSpeed * upgLevel);
}

static simulated function ModifyRateOfFirePassive(out float rateOfFireFactor, int upgLevel)
{
	local float Fb_AttackSpeed;

	Fb_AttackSpeed = default.Cfg_AttackSpeed;
	if (Fb_AttackSpeed == 0)
		Fb_AttackSpeed = default.AttackSpeed;
	rateOfFireFactor = 1.0f / (1.0f / rateOfFireFactor + Fb_AttackSpeed * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Perk_Berserker"
}
