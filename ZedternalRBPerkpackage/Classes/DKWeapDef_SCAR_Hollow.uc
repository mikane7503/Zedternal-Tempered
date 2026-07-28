class DKWeapDef_SCAR_Hollow extends KFWeapDef_SCAR
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Obsidian Hunger";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_AssaultRifle_SCAR_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_SCAR_Hollow"
}
