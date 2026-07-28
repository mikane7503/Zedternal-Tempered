class DKWeapDef_Rifle_FrostShotgunAxe_Hollow extends KFWeapDef_Rifle_FrostShotgunAxe
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Glacial Severance";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_FrostShotgunAxe_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Rifle_FrostShotgunAxe_Hollow"
}
