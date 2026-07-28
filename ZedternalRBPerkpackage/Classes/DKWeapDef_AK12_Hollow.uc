class DKWeapDef_AK12_Hollow extends KFWeapDef_AK12
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Voidsplinter Choir";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_AK12_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_AK12_Hollow"
}
