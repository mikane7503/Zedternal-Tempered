class DKWeapDef_M99_Hollow extends KFWeapDef_M99
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Pierce";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_M99_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_M99_Hollow"
}
