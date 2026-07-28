class DKWeapDef_Crovel_Reforged extends KFWeapDef_Crovel
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Blunt_Crovel";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Blunt_Crovel_Reforged"
	BuyPrice=700
	Name="Default__DKWeapDef_Crovel_Reforged"
}
