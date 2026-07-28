class DKWeapDef_9mm_Reforged extends KFWeapDef_9mm
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_9mm";

static function string GetItemLocalization(string KeyName)
{
	local array<string> Strings;
	local string Localization;

	ParseStringIntoArray(DEFAULT_WEAPON_PATH, Strings, ".", True);
	Localization = Localize(Strings[1], KeyName, Strings[0]);
	if (KeyName ~= "ItemName")
		return Chr(9733) @ Localization;
	else
		return Localization;
}

defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_9mm_Reforged"
	AmmoPricePerMag=34
	Name="Default__DKWeapDef_9mm_Reforged"
}
