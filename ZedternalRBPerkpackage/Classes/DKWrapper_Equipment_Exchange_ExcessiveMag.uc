// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_Exchange_ExcessiveMag
class DKWrapper_Equipment_Exchange_ExcessiveMag extends ZRUpgrade_Equipment_Exchange_ExcessiveMag
	config(ZedternalUnlimited);

var config float Cfg_ReloadRate;
var config float Cfg_MagSize;
var config int MODEVERSION;

// Mag size and reload rate run in simulated passives (client-predicted). Config
// vars do not reach dedicated clients, so the tuned values are replicated via
// the balance helper and read here. See SpawnBalanceRepHelper / PopulateHelper.
const SLOT_MagSize = 202;
const SLOT_ReloadRate = 203;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ReloadRate = 0.3f;
		default.Cfg_MagSize = 2.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[202] = default.Cfg_MagSize;
	H.Values[203] = default.Cfg_ReloadRate;
}

static simulated function ModifyMagSizeAndNumberPassive(out float magazineCapacityFactor, int upgLevel)
{
	local DKBalanceRepHelper H;
	local float Val_MagSize;

	H = class'DKBalanceRepHelper'.static.GetHelper(class'WorldInfo'.static.GetWorldInfo());
	if (H != None && H.Values[202] != 0.0f)
		Val_MagSize = H.Values[202];
	else
		Val_MagSize = default.MagSize;
	magazineCapacityFactor += Val_MagSize * upgLevel;
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
	local DKBalanceRepHelper H;
	local float Val_ReloadRate;

	H = class'DKBalanceRepHelper'.static.GetHelper(class'WorldInfo'.static.GetWorldInfo());
	if (H != None && H.Values[203] != 0.0f)
		Val_ReloadRate = H.Values[203];
	else
		Val_ReloadRate = default.ReloadRate;
	reloadRateFactor = 1.0f / (1.0f / reloadRateFactor - Val_ReloadRate * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_Exchange_ExcessiveMag"
}
