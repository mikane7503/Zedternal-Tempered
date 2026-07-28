// Wrapper for ZedternalReborn.WMUpgrade_Equipment_HealthUp
class DKWrapper_Equipment_HealthUp extends WMUpgrade_Equipment_HealthUp
	config(ZedternalUnlimited);

var config int Cfg_Health;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Health = 10;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += default.Cfg_Health * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_HealthUp"
}
