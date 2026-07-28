// Wrapper for ZedternalReborn.WMUpgrade_Equipment_SpareBatteries
class DKWrapper_Equipment_SpareBatteries extends WMUpgrade_Equipment_SpareBatteries
	config(ZedternalUnlimited);

var config float Cfg_Recharge;
var config int MODEVERSION;

const SLOT_Recharge = 0;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Recharge = 0.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[0] = default.Cfg_Recharge;
}

static simulated function GetBatteryRateScale(out float InRechargeRateFL, out float InRechargeRateNVG, int upgLevel, KFPawn OwnerPawn)
{
	local DKBalanceRepHelper H;
	local float Val_Recharge;

	H = class'DKBalanceRepHelper'.static.GetHelper(OwnerPawn);
	if (H != None && H.Values[0] != 0.0f)
		Val_Recharge = H.Values[0];
	else
		Val_Recharge = default.Recharge;
	InRechargeRateFL = 1.0f / (1.0f / InRechargeRateFL + Val_Recharge * upgLevel);
	InRechargeRateNVG = 1.0f / (1.0f / InRechargeRateNVG + Val_Recharge * upgLevel);
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_SpareBatteries"
}
