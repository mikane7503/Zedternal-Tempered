// Wrapper for ZedternalReborn.WMUpgrade_Skill_ConcussionRounds
class ZTWrapper_Skill_ConcussionRounds extends WMUpgrade_Skill_ConcussionRounds config(ZedternalUnlimited);

var config array<float> Cfg_Effect;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Effect[0] = 0.25f;
		default.Cfg_Effect[1] = 0.60f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Effect.Length = 2;
		default.Cfg_Effect[0] = 0.250000f;
		default.Cfg_Effect[1] = 0.600000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyStumblePowerPassive(out float stumblePowerFactor, int upgLevel)
{
	stumblePowerFactor += default.Cfg_Effect[upgLevel - 1];
}

static function ModifyStunPowerPassive(out float stunPowerFactor, int upgLevel)
{
	stunPowerFactor += default.Cfg_Effect[upgLevel - 1];
}

static function ModifyKnockdownPowerPassive(out float knockdownPowerFactor, int upgLevel)
{
	knockdownPowerFactor += default.Cfg_Effect[upgLevel - 1];
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_ConcussionRounds"
}
