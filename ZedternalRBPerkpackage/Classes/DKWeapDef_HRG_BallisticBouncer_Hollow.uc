class DKWeapDef_HRG_BallisticBouncer_Hollow extends KFWeapDef_HRG_BallisticBouncer
	abstract;

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_BallisticBouncer_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_BallisticBouncer_Hollow"
}
