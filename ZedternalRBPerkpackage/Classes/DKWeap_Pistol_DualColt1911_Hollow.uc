class DKWeap_Pistol_DualColt1911_Hollow extends KFWeap_Pistol_DualColt1911;

// ===================================================================
// HOLLOW VARIANT — Pistol_DualColt1911
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
	return "Twin Eclipses";
}


defaultproperties
{
	Name="Default__DKWeap_Pistol_DualColt1911_Hollow"
}
