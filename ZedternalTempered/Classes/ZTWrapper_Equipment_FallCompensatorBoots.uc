// Wrapper for ZedternalReborn.WMUpgrade_Equipment_FallCompensatorBoots
class ZTWrapper_Equipment_FallCompensatorBoots extends WMUpgrade_Equipment_FallCompensatorBoots config(ZedternalUnlimited);

var config float Cfg_DamageResistance;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_DamageResistance = 0.4f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_DamageResistance = 0.250000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (ClassIsChildOf(DamageType, class'KFDT_Falling'))
		InDamage -= Round(float(DefaultDamage) * FMin(default.Cfg_DamageResistance * upgLevel, 0.5f));
}

defaultproperties
{
	Name="Default__ZTWrapper_Equipment_FallCompensatorBoots"
}
