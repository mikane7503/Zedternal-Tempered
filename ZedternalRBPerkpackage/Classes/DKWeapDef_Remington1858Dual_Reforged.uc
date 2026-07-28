class DKWeapDef_Remington1858Dual_Reforged extends KFWeapDef_Remington1858Dual
	abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Revolver_DualRem1858";

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
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Revolver_DualRem1858_Reforged"
	BuyPrice=700
	AmmoPricePerMag=56
	Name="Default__DKWeapDef_Remington1858Dual_Reforged"
}
