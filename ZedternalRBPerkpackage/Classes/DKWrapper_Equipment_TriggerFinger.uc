// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_TriggerFinger
class DKWrapper_Equipment_TriggerFinger extends ZRUpgrade_Equipment_TriggerFinger
	config(ZedternalUnlimited);

var config Float Cfg_AttackSpeed;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_AttackSpeed = 0.10f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static simulated function ModifyRateOfFirePassive(out float rateOfFireFactor, int upgLevel)
{
	local Float Fb_AttackSpeed;

	Fb_AttackSpeed = default.Cfg_AttackSpeed;
	if (Fb_AttackSpeed == 0)
		Fb_AttackSpeed = default.AttackSpeed;
	rateOfFireFactor = 1.0f / (1.0f / rateOfFireFactor + Fb_AttackSpeed * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_TriggerFinger"
}
