class DKWeap_HRG_SonicGun_Hollow extends KFWeap_HRG_SonicGun;

// ===================================================================
// HOLLOW VARIANT — HRG_SonicGun
//
// This is a Hollow weapon variant. It extends the base weapon directly.
// Stat bonuses are applied through DKUpgrade_Perk_Hollow's ModifyXXX
// functions using DKHollowWeaponData for bonus values.
//
// - BuyPrice: 0 (free once unlocked)
// - Not eligible for weapon upgrades
// - Only visible to the player who completed all 5 conditions
// ===================================================================


simulated function string GetHumanReadableName()
{
	return "Rift Howl";
}


defaultproperties
{
	Name="Default__DKWeap_HRG_SonicGun_Hollow"
}
