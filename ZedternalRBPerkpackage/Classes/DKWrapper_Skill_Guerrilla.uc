// Wrapper for ZedternalReborn.WMUpgrade_Skill_Guerrilla
class DKWrapper_Skill_Guerrilla extends WMUpgrade_Skill_Guerrilla
	config(ZedternalUnlimited);

var config array<float> Cfg_Bonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Bonus[0] = 0.1f;
		default.Cfg_Bonus[1] = 0.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
	damageFactor += default.Cfg_Bonus[upgLevel - 1];
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	InHealth += Round(float(DefaultHealth) * default.Cfg_Bonus[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Guerrilla"
}
