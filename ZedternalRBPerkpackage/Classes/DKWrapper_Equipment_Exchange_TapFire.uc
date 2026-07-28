// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_Exchange_TapFire
class DKWrapper_Equipment_Exchange_TapFire extends ZRUpgrade_Equipment_Exchange_TapFire
	config(ZedternalUnlimited);

var config float Cfg_Recoil;
var config float Cfg_AttackSpeed;
var config int MODEVERSION;

// Attack speed, rate of fire and recoil run in simulated passives
// (client-predicted). Config vars do not reach dedicated clients, so the tuned
// values are replicated via the balance helper and read here.
const SLOT_AttackSpeed = 206;
const SLOT_Recoil = 207;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Recoil = 1.0f;
		default.Cfg_AttackSpeed = 0.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function PopulateHelper(DKBalanceRepHelper H)
{
	H.Values[206] = default.Cfg_AttackSpeed;
	H.Values[207] = default.Cfg_Recoil;
}

static simulated function ModifyMeleeAttackSpeedPassive(out float durationFactor, int upgLevel)
{
	local DKBalanceRepHelper H;
	local float Val_AttackSpeed;

	H = class'DKBalanceRepHelper'.static.GetHelper(class'WorldInfo'.static.GetWorldInfo());
	if (H != None && H.Values[206] != 0.0f)
		Val_AttackSpeed = H.Values[206];
	else
		Val_AttackSpeed = default.AttackSpeed;
	durationFactor = 1.0f / (1.0f / durationFactor - Val_AttackSpeed * upgLevel);
}

static simulated function ModifyRateOfFirePassive(out float rateOfFireFactor, int upgLevel)
{
	local DKBalanceRepHelper H;
	local float Val_AttackSpeed;

	H = class'DKBalanceRepHelper'.static.GetHelper(class'WorldInfo'.static.GetWorldInfo());
	if (H != None && H.Values[206] != 0.0f)
		Val_AttackSpeed = H.Values[206];
	else
		Val_AttackSpeed = default.AttackSpeed;
	rateOfFireFactor = 1.0f / (1.0f / rateOfFireFactor - Val_AttackSpeed * upgLevel);
}

static simulated function ModifyRecoilPassive(out float recoilFactor, int upgLevel)
{
	local DKBalanceRepHelper H;
	local float Val_Recoil;

	H = class'DKBalanceRepHelper'.static.GetHelper(class'WorldInfo'.static.GetWorldInfo());
	if (H != None && H.Values[207] != 0.0f)
		Val_Recoil = H.Values[207];
	else
		Val_Recoil = default.Recoil;
	recoilFactor -= recoilFactor * FMin(Val_Recoil * upgLevel, 0.8f);
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_Exchange_TapFire"
}
