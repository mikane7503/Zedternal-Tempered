// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_TestEquipment
class DKWrapper_Equipment_TestEquipment extends ZRUpgrade_Equipment_TestEquipment
	config(ZedternalUnlimited);

var config int Cfg_Health;
var config int Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Health = 10;
		default.Cfg_Armor = 10;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	//No limit as we have defined -1 in the EquipmentBonus maxValue variable
	MaxArmor += default.Cfg_Armor * upgLevel;
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	//No limit as we have defined -1 in the EquipmentBonus maxValue variable
	InHealth += default.Cfg_Health * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_TestEquipment"
}
