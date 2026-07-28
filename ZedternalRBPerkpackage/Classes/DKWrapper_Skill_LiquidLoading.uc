// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_LiquidLoading
class DKWrapper_Skill_LiquidLoading extends ZRUpgrade_Skill_LiquidLoading
	config(ZedternalUnlimited);

var config array<float> Cfg_ReloadRate;
var config int MODEVERSION;

const SLOT_ReloadRate_0 = 61;
const SLOT_ReloadRate_1 = 62;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_ReloadRate[0] = 1.2f;
		default.Cfg_ReloadRate[1] = 1.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[61] = default.Cfg_ReloadRate[0];
	H.Values[62] = default.Cfg_ReloadRate[1];
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKBalanceRepHelper H;
	local float Val_ReloadRate_0;
	local float Val_ReloadRate_1;
	local float Resolved_ReloadRate;

	H = class'DKBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[61] != 0.0f)
		Val_ReloadRate_0 = H.Values[61];
	else
		Val_ReloadRate_0 = default.ReloadRate[0];
	if (H != None && H.Values[62] != 0.0f)
		Val_ReloadRate_1 = H.Values[62];
	else
		Val_ReloadRate_1 = default.ReloadRate[1];
	if (upgLevel > 1)
		Resolved_ReloadRate = Val_ReloadRate_1;
	else
		Resolved_ReloadRate = Val_ReloadRate_0;
	if (OwnerPawn != None && VSizeSq(OwnerPawn.Velocity) <= 0)
	{
		InReloadRateScale = 1.0f / (1.0f / InReloadRateScale * Resolved_ReloadRate);
	}
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_LiquidLoading"
}
