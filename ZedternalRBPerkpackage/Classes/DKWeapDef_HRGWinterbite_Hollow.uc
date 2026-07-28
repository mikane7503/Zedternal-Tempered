class DKWeapDef_HRGWinterbite_Hollow extends KFWeapDef_HRGWinterbite
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Frost Absence";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_HRGWinterbite_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRGWinterbite_Hollow"
}
