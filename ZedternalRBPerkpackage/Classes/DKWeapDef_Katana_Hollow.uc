class DKWeapDef_Katana_Hollow extends KFWeapDef_Katana
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Severance Glass";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Edged_Katana_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Katana_Hollow"
}
