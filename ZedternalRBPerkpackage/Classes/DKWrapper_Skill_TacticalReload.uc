// Wrapper for ZedternalReborn.WMUpgrade_Skill_TacticalReload
class DKWrapper_Skill_TacticalReload extends WMUpgrade_Skill_TacticalReload
	config(ZedternalUnlimited);

var config float Cfg_ReloadRateDeluxe;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ReloadRateDeluxe = 0.3f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
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
	Name="Default__DKWrapper_Skill_TacticalReload"
}
