// Wrapper for ZedternalReborn.WMUpgrade_Skill_Dreadnaught
class DKWrapper_Skill_Dreadnaught extends WMUpgrade_Skill_Dreadnaught
	config(ZedternalUnlimited);

var config array<float> Cfg_Health;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Health[0] = 0.25f;
		default.Cfg_Health[1] = 0.6f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += Round(float(DefaultHealth) * default.Cfg_Health[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Dreadnaught"
}
