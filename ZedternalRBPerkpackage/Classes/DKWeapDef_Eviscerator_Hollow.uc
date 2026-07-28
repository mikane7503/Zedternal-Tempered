class DKWeapDef_Eviscerator_Hollow extends KFWeapDef_Eviscerator
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Thirst";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Eviscerator_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Eviscerator_Hollow"
}
