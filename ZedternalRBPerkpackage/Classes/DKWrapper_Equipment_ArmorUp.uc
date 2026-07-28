// Wrapper for ZedternalReborn.WMUpgrade_Equipment_ArmorUp
class DKWrapper_Equipment_ArmorUp extends WMUpgrade_Equipment_ArmorUp
	config(ZedternalUnlimited);

var config int Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Armor = 10;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	MaxArmor += default.Cfg_Armor * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_ArmorUp"
}
