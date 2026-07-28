class DKWeapDef_MedicPistol_Reforged extends KFWeapDef_MedicPistol
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Pistol_Medic";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Pistol_Medic_Reforged"
	BuyPrice=700
	AmmoPricePerMag=28
	Name="Default__DKWeapDef_MedicPistol_Reforged"
}
