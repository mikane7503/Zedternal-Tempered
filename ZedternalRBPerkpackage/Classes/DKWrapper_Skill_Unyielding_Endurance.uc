// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_Unyielding_Endurance
class DKWrapper_Skill_Unyielding_Endurance extends ZRUpgrade_Skill_Unyielding_Endurance
	config(ZedternalUnlimited);

var config array<float> Cfg_Health;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Health[0] = 0.15f;
		default.Cfg_Health[1] = 0.30f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	// upgLevel will either be 1 or 2 depending on version of the skill (1 for base and 2 for deluxe). Arrays are always zero-based indexing
	// so we have to put upgLevel - 1 when accessing the array to avoid a out of bounds exception.
	InHealth += Round(float(DefaultHealth) * default.Cfg_Health[upgLevel - 1]);
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Unyielding_Endurance"
}
