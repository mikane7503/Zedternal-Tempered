// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_RocketBoots
class DKWrapper_Equipment_RocketBoots extends ZRUpgrade_Equipment_RocketBoots
	config(ZedternalUnlimited);

var config float Cfg_MoveSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MoveSpeed = 0.10f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	local float Fb_MoveSpeed;

	Fb_MoveSpeed = default.Cfg_MoveSpeed;
	if (Fb_MoveSpeed == 0)
		Fb_MoveSpeed = default.MoveSpeed;
	speedFactor += Fb_MoveSpeed * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_RocketBoots"
}
