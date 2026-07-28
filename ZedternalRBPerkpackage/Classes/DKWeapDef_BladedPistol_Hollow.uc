class DKWeapDef_BladedPistol_Hollow extends KFWeapDef_BladedPistol
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Mercurial Fang";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Bladed_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_BladedPistol_Hollow"
}
