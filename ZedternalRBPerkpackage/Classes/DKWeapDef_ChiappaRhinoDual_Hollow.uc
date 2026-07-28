class DKWeapDef_ChiappaRhinoDual_Hollow extends KFWeapDef_ChiappaRhinoDual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Mercury Thorns";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_ChiappaRhinoDual_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_ChiappaRhinoDual_Hollow"
}
