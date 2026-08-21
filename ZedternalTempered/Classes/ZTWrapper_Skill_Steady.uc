// Wrapper for ZedternalReborn.WMUpgrade_Skill_Steady
class ZTWrapper_Skill_Steady extends WMUpgrade_Skill_Steady config(ZedternalUnlimited);

var config array<float> Cfg_Recoil;
var config float Cfg_Bob;
var config int MODEVERSION;

const SLOT_Recoil_0 = 40;
const SLOT_Recoil_1 = 41;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Recoil[0] = 0.3f;
		default.Cfg_Recoil[1] = 0.75f;
		default.Cfg_Bob = 0.11f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Recoil.Length = 2;
		default.Cfg_Recoil[0] = 0.300000f;
		default.Cfg_Recoil[1] = 0.750000f;
		default.Cfg_Bob = 0.110000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[40] = default.Cfg_Recoil[0];
	H.Values[41] = default.Cfg_Recoil[1];
}

static simulated function ModifyWeaponBopDampingPassive(out float bobDampFactor, int upgLevel)
{
	local float Fb_Bob;

	Fb_Bob = default.Cfg_Bob;
	if (Fb_Bob == 0)
		Fb_Bob = default.Bob;
	bobDampFactor += Fb_Bob;
}

static simulated function ModifyRecoil(out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
	local ZTBalanceRepHelper H;
	local float Val_Recoil_0;
	local float Val_Recoil_1;
	local float Resolved_Recoil;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[40] != 0.0f)
		Val_Recoil_0 = H.Values[40];
	else
		Val_Recoil_0 = default.Recoil[0];
	if (H != None && H.Values[41] != 0.0f)
		Val_Recoil_1 = H.Values[41];
	else
		Val_Recoil_1 = default.Recoil[1];
	if (upgLevel > 1)
		Resolved_Recoil = Val_Recoil_1;
	else
		Resolved_Recoil = Val_Recoil_0;
	if (KFW != None)
		InRecoilModifier -= DefaultRecoilModifier * Resolved_Recoil;
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_Steady"
}
