class DKWeapDef_9mmDual_Hollow extends KFWeapDef_9mmDual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Needles";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Dual9mm_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_9mmDual_Hollow"
}
