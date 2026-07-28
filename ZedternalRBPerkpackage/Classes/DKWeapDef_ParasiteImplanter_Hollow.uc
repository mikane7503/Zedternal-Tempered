class DKWeapDef_ParasiteImplanter_Hollow extends KFWeapDef_ParasiteImplanter
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Seed";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_ParasiteImplanter_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_ParasiteImplanter_Hollow"
}
