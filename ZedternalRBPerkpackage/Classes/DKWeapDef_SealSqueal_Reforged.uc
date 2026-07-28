class DKWeapDef_SealSqueal_Reforged extends KFWeapDef_SealSqueal
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_RocketLauncher_SealSqueal";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_RocketLauncher_SealSqueal_Reforged"
	BuyPrice=3850
	AmmoPricePerMag=210
	Name="Default__DKWeapDef_SealSqueal_Reforged"
}
