class ZTWeapDef_HRG_BallisticBouncer_Hollow extends KFWeapDef_HRG_BallisticBouncer abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Rift Echo";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalTempered.ZTWeap_HRG_BallisticBouncer_Hollow"
	BuyPrice=0
	Name="Default__ZTWeapDef_HRG_BallisticBouncer_Hollow"
}
