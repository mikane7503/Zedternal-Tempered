class DKWeapDef_PowerGloves_Reforged extends KFWeapDef_PowerGloves
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Blunt_PowerGloves";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_PowerGloves_Reforged"
	BuyPrice=5600
	Name="Default__DKWeapDef_PowerGloves_Reforged"
}
