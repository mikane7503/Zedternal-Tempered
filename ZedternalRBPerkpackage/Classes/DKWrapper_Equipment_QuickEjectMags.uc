// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_QuickEjectMags
class DKWrapper_Equipment_QuickEjectMags extends ZRUpgrade_Equipment_QuickEjectMags
	config(ZedternalUnlimited);

var config Float Cfg_ReloadRate;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ReloadRate = 0.10f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
	local Float Fb_ReloadRate;

	Fb_ReloadRate = default.Cfg_ReloadRate;
	if (Fb_ReloadRate == 0)
		Fb_ReloadRate = default.ReloadRate;
	reloadRateFactor = 1.0f / (1.0f / reloadRateFactor + Fb_ReloadRate * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_QuickEjectMags"
}
