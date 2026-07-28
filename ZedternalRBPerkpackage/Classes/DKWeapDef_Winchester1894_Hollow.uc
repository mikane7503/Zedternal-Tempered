class DKWeapDef_Winchester1894_Hollow extends KFWeapDef_Winchester1894
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Dusk Needle";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_Winchester1894_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Winchester1894_Hollow"
}
