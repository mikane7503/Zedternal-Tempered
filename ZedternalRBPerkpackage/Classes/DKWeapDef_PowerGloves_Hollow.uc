class DKWeapDef_PowerGloves_Hollow extends KFWeapDef_PowerGloves
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Voidgrasp";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_PowerGloves_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_PowerGloves_Hollow"
}
