class DKWeapDef_AbominationAxe_Hollow extends KFWeapDef_AbominationAxe
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Severance";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Edged_AbominationAxe_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_AbominationAxe_Hollow"
}
