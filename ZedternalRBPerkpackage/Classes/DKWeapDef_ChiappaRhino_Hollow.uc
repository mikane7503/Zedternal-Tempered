class DKWeapDef_ChiappaRhino_Hollow extends KFWeapDef_ChiappaRhino
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Mercury Thorn";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_ChiappaRhino_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_ChiappaRhino_Hollow"
}
