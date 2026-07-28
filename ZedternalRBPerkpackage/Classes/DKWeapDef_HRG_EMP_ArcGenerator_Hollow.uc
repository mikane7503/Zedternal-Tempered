class DKWeapDef_HRG_EMP_ArcGenerator_Hollow extends KFWeapDef_HRG_EMP_ArcGenerator
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Void Sigil";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_HRG_EMP_ArcGenerator_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_HRG_EMP_ArcGenerator_Hollow"
}
