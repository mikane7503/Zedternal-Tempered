// Wrapper for ZedternalReborn.WMUpgrade_Skill_HighCapacityMags
class ZTWrapper_Skill_HighCapacityMags extends WMUpgrade_Skill_HighCapacityMags config(ZedternalUnlimited);

var config array<float> Cfg_MagCapacity;
var config int MODEVERSION;

const SLOT_MagCapacity_0 = 11;
const SLOT_MagCapacity_1 = 12;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_MagCapacity[0] = 0.3f;
		default.Cfg_MagCapacity[1] = 0.75f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_MagCapacity.Length = 2;
		default.Cfg_MagCapacity[0] = 0.300000f;
		default.Cfg_MagCapacity[1] = 0.750000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function PopulateHelper(ZTBalanceRepHelper H)
{
	H.Values[11] = default.Cfg_MagCapacity[0];
	H.Values[12] = default.Cfg_MagCapacity[1];
}

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
	local ZTBalanceRepHelper H;
	local float Val_MagCapacity_0;
	local float Val_MagCapacity_1;
	local float Resolved_MagCapacity;

	H = class'ZTBalanceRepHelper'.static.GetHelper(KFW);
	if (H != None && H.Values[11] != 0.0f)
		Val_MagCapacity_0 = H.Values[11];
	else
		Val_MagCapacity_0 = default.MagCapacity[0];
	if (H != None && H.Values[12] != 0.0f)
		Val_MagCapacity_1 = H.Values[12];
	else
		Val_MagCapacity_1 = default.MagCapacity[1];
	if (upgLevel > 1)
		Resolved_MagCapacity = Val_MagCapacity_1;
	else
		Resolved_MagCapacity = Val_MagCapacity_0;
	InMagazineCapacity += Round(float(DefaultMagazineCapacity) * Resolved_MagCapacity);
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_HighCapacityMags"
}
