// Wrapper for ZedternalReborn.WMUpgrade_Skill_AmmoVest
class DKWrapper_Skill_AmmoVest extends WMUpgrade_Skill_AmmoVest
	config(ZedternalUnlimited);

var config array<float> Cfg_Ammo;
var config array<int> Cfg_Weight;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Ammo[0] = 0.3f;
		default.Cfg_Ammo[1] = 0.75f;
		default.Cfg_Weight[0] = 2;
		default.Cfg_Weight[1] = 5;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ApplyWeightLimits(out int InWeightLimit, int DefaultWeightLimit, int upgLevel)
{
	InWeightLimit += default.Cfg_Weight[upgLevel - 1];
}

static simulated function ModifySpareAmmoAmountPassive(out float spareAmmoFactor, int upgLevel)
{
	local float Fb_Ammo;

	if (default.Cfg_Ammo.Length > 0 && default.Cfg_Ammo[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Ammo.Length > 1)
			Fb_Ammo = default.Cfg_Ammo[1];
		else
			Fb_Ammo = default.Cfg_Ammo[0];
	}
	else
	{
		if (upgLevel > 1 && default.Ammo.Length > 1)
			Fb_Ammo = default.Ammo[1];
		else
			Fb_Ammo = default.Ammo[0];
	}
	spareAmmoFactor += Fb_Ammo;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_AmmoVest"
}
