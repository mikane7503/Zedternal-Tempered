class DKWeapDef_HRGScorcher_Hollow extends KFWeapDef_HRGScorcher
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Ember Hollow";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_HRGScorcher_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRGScorcher_Hollow"
}
