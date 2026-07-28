class DKWeapDef_DeagleDual_Hollow extends KFWeapDef_DeagleDual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Paired Maws";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualDeagle_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_DeagleDual_Hollow"
}
