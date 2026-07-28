class DKWeapDef_DragonsBreath_Reforged extends KFWeapDef_DragonsBreath
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Shotgun_DragonsBreath";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Shotgun_DragonsBreath_Reforged"
	BuyPrice=2275
	AmmoPricePerMag=84
	Name="Default__DKWeapDef_DragonsBreath_Reforged"
}
