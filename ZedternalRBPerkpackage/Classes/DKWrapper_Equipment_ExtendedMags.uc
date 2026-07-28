// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_ExtendedMags
class DKWrapper_Equipment_ExtendedMags extends ZRUpgrade_Equipment_ExtendedMags
	config(ZedternalUnlimited);

var config float Cfg_MagSize;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MagSize = 0.10f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static simulated function ModifyMagSizeAndNumberPassive(out float magazineCapacityFactor, int upgLevel)
{
	local float Fb_MagSize;

	Fb_MagSize = default.Cfg_MagSize;
	if (Fb_MagSize == 0)
		Fb_MagSize = default.MagSize;
	magazineCapacityFactor += Fb_MagSize * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_ExtendedMags"
}
