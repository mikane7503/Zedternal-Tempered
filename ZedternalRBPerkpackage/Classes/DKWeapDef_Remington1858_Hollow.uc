class DKWeapDef_Remington1858_Hollow extends KFWeapDef_Remington1858
	abstract;

static function string GetItemLocalization(string KeyName)
{
	if (KeyName ~= "ItemName")
		return "Marrow Whisper";
	else if (KeyName ~= "ItemDescription")
		return "An absence given form. Perfected through mastery.";
	else
		return "";
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Revolver_Rem1858_Hollow"
	BuyPrice=0
	Name="Default__DKWeapDef_Remington1858_Hollow"
}
