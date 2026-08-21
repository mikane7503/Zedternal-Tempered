class ZTWeapDef_C4_Hollow extends KFWeapDef_C4 abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Sigil";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_Thrown_C4_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_C4_Hollow"
}
