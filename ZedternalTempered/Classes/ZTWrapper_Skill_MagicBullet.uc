// Wrapper for ZedternalReborn.WMUpgrade_Skill_MagicBullet
class ZTWrapper_Skill_MagicBullet extends WMUpgrade_Skill_MagicBullet config(ZedternalUnlimited);

var config array<int> Cfg_Ammo;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Ammo[0] = 1;
		default.Cfg_Ammo[1] = 2;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Cfg_Ammo.Length = 2;
		default.Cfg_Ammo[0] = 1;
		default.Cfg_Ammo[1] = 2;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function AddVampireHealth(out int InHealth, int DefaultHealth, int upgLevel, KFPlayerController KFPC, class<DamageType> DT)
{
	local WMUpgrade_Skill_MagicBullet_Helper UPG;

	UPG = GetHelper(KFPC.Pawn);
	if (UPG != None)
	{
		if (UPG.Player.WorldInfo.NetMode == NM_Standalone) // For single player
			UPG.StandaloneUpdateAmmo(default.Cfg_Ammo[upgLevel - 1]);
		else // For servers
			UPG.ServerUpdateAmmo(default.Cfg_Ammo[upgLevel - 1]);
	}
}

defaultproperties
{
	Name="Default__ZTWrapper_Skill_MagicBullet"
}
