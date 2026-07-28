class DKWeapDef_Doshinegun_Hollow extends KFWeapDef_Doshinegun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Ash Cascade";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_Doshinegun_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Doshinegun_Hollow"
}
