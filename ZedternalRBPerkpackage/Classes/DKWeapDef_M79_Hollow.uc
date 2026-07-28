class DKWeapDef_M79_Hollow extends KFWeapDef_M79
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Breach Hollow";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_GrenadeLauncher_M79_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_M79_Hollow"
}
