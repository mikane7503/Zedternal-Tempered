// Wrapper for HowdyZTRExt.ZRUpgrade_Skill_Armorer
class DKWrapper_Skill_Armorer extends ZRUpgrade_Skill_Armorer
	config(ZedternalUnlimited);

var config float Cfg_SupplierArmor;
var config array<float> Cfg_Armor;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Cfg_SupplierArmor = 0.3f;;
		default.Cfg_Armor[0] = 0.2f;
		default.Cfg_Armor[1] = 0.40f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
	MaxArmor += Round(float(DefaultArmor) * default.Cfg_Armor[upgLevel - 1]);
}

static simulated function SupplierModifiers(int upgLevel, out float PrimaryAmmoPercentage, out float SecondaryAmmoPercentage, out float ArmorPercentage, out int GrenadeAmount)
{
	local float Fb_SupplierArmor;

	Fb_SupplierArmor = default.Cfg_SupplierArmor;
	if (Fb_SupplierArmor == 0)
		Fb_SupplierArmor = default.SupplierArmor;
	ArmorPercentage += Fb_SupplierArmor;
}

defaultproperties
{
	Name="Default__DKWrapper_Skill_Armorer"
}
