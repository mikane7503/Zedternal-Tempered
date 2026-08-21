class ZTWeapDef_M16M203_Hollow extends KFWeapDef_M16M203 abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Dusk Fracture";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_AssaultRifle_M16M203_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_M16M203_Hollow"
}
