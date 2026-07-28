class DKWeapDef_Colt1911_Hollow extends KFWeapDef_Colt1911
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Ash Sigil";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Colt1911_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Colt1911_Hollow"
}
