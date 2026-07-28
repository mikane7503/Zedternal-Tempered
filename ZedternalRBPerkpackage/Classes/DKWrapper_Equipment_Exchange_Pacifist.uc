// Wrapper for HowdyZTRExt.ZRUpgrade_Equipment_Exchange_Pacifist
class DKWrapper_Equipment_Exchange_Pacifist extends ZRUpgrade_Equipment_Exchange_Pacifist
	config(ZedternalUnlimited);

var config int Cfg_Health;
var config float Cfg_Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_Health = 49;
		default.Cfg_Damage = 0.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
	static.StaticSaveConfig();

	// Update display values
}

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
	damageFactor -= default.Cfg_Damage * upgLevel;
}

static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
	//No limit as we have defined -1 in the EquipmentBonus maxValue variable
	InHealth += default.Cfg_Health * upgLevel;
}

defaultproperties
{
	Name="Default__DKWrapper_Equipment_Exchange_Pacifist"
}
