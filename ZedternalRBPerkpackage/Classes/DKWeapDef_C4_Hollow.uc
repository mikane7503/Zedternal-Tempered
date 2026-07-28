class DKWeapDef_C4_Hollow extends KFWeapDef_C4
	abstract;

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Thrown_C4_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_C4_Hollow"
}
