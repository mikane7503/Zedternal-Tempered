class DKWeapDef_Zweihander_Hollow extends KFWeapDef_Zweihander
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Severance";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Edged_Zweihander_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Zweihander_Hollow"
}
