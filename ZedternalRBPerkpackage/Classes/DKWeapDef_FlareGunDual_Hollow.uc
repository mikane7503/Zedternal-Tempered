class DKWeapDef_FlareGunDual_Hollow extends KFWeapDef_FlareGunDual
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Twin Dusk Sigils";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_DualFlare_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_FlareGunDual_Hollow"
}
