class ZTWeapDef_MicrowaveGun_Reforged extends KFWeapDef_MicrowaveGun abstract;

const DEFAULT_WEAPON_PATH = "KFGameContent.KFWeap_Beam_Microwave";

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
	WeaponClassPath="ZedternalTempered.ZTWeap_Beam_Microwave_Reforged"
	BuyPrice=5250
	AmmoPricePerMag=280
	Name="Default__ZTWeapDef_MicrowaveGun_Reforged"
}
