class DKWeapDef_AA12_Hollow extends KFWeapDef_AA12
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Obsidian Maw";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_AA12_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_AA12_Hollow"
}
