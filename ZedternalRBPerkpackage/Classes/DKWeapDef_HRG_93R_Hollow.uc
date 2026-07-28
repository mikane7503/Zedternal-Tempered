class DKWeapDef_HRG_93R_Hollow extends KFWeapDef_HRG_93R
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Fracture Sigh";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_93R_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_93R_Hollow"
}
