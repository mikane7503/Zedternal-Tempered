class DKWeapDef_FlareGun_Hollow extends KFWeapDef_FlareGun
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Dusk Sigil";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Flare_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_FlareGun_Hollow"
}
