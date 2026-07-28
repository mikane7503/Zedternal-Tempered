class DKWeapDef_Minigun_Hollow extends KFWeapDef_Minigun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Void Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Minigun_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Minigun_Hollow"
}
