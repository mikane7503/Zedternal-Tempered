// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_Exchange_Bulwark
class DKWrapper_Equipment_Exchange_Bulwark extends ZRUpgrade_Equipment_Exchange_Bulwark
	config(ZedternalUnlimited);

var config float Cfg_MoveSpeed;
var config float Cfg_Bonus;
var config int MODEVERSION;

// Speed runs in a simulated passive (client-predicted movement). Config vars
// do not reach dedicated clients, so the tuned value is replicated via the
// balance helper and read here. See SpawnBalanceRepHelper / PopulateHelper.
const SLOT_MoveSpeed = 200;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MoveSpeed = 0.50f;
		default.Cfg_Bonus = 7;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[200] = default.Cfg_MoveSpeed;
}

static function ApplyWeightLimits(out int InWeightLimit, int DefaultWeightLimit, int upgLevel)
{
	InWeightLimit += default.Cfg_Bonus * upgLevel;
}

static simulated function ModifySpeedPassive(out float speedFactor, int upgLevel)
{
	local DKBalanceRepHelper H;
	local float Val_MoveSpeed;

	H = class'DKBalanceRepHelper'.static.GetHelper(class'WorldInfo'.static.GetWorldInfo());
	if (H != None && H.Values[200] != 0.0f)
		Val_MoveSpeed = H.Values[200];
	else
		Val_MoveSpeed = default.MoveSpeed;
	speedFactor -= Val_MoveSpeed * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_Exchange_Bulwark"
}
