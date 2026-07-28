class DKWeapDef_AF2011_Hollow extends KFWeapDef_AF2011
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Mercury Shard";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_AF2011_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_AF2011_Hollow"
}
