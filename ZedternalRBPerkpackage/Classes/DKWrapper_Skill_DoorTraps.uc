// Wrapper for ZedternalReborn.WMUpgrade_Skill_DoorTraps
class DKWrapper_Skill_DoorTraps extends WMUpgrade_Skill_DoorTraps
	config(ZedternalUnlimited);

var config array<int> Cfg_ExtraGrenades;
var config array<float> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ExtraGrenades[0] = 4;
		default.Cfg_ExtraGrenades[1] = 8;
		default.Cfg_Bonus[0] = 0.75f;
		default.Cfg_Bonus[1] = 2.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function ModifyWeldingRate(out float InFastenRate, float DefaultFastenRate, out float InUnfastenRate, float DefaultUnfastenRate, int upgLevel)
{
	local float Fb_Bonus;

	if (default.Cfg_Bonus.Length > 0 && default.Cfg_Bonus[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_Bonus.Length > 1)
			Fb_Bonus = default.Cfg_Bonus[1];
		else
			Fb_Bonus = default.Cfg_Bonus[0];
	}
	else
	{
		if (upgLevel > 1 && default.Bonus.Length > 1)
			Fb_Bonus = default.Bonus[1];
		else
			Fb_Bonus = default.Bonus[0];
	}
	InFastenRate += DefaultFastenRate * Fb_Bonus;
	InUnfastenRate += DefaultUnfastenRate * Fb_Bonus;
}

static simulated function ModifySpareGrenadeAmount(out int SpareGrenade, int DefaultSpareGrenade, int upgLevel)
{
	local int Fb_ExtraGrenades;

	if (default.Cfg_ExtraGrenades.Length > 0 && default.Cfg_ExtraGrenades[0] != 0)
	{
		if (upgLevel > 1 && default.Cfg_ExtraGrenades.Length > 1)
			Fb_ExtraGrenades = default.Cfg_ExtraGrenades[1];
		else
			Fb_ExtraGrenades = default.Cfg_ExtraGrenades[0];
	}
	else
	{
		if (upgLevel > 1 && default.ExtraGrenades.Length > 1)
			Fb_ExtraGrenades = default.ExtraGrenades[1];
		else
			Fb_ExtraGrenades = default.ExtraGrenades[0];
	}
	SpareGrenade += Fb_ExtraGrenades;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_DoorTraps"
}
