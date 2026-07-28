// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_ExtraNades
class DKWrapper_Skill_ExtraNades extends ZRUpgrade_Skill_ExtraNades
	config(ZedternalUnlimited);

var config array<int> Cfg_ExtraGrenades;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ExtraGrenades[0] = 2;
		default.Cfg_ExtraGrenades[1] = 4;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
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
	Name="Default__DKWrapper_Skill_ExtraNades"
}
