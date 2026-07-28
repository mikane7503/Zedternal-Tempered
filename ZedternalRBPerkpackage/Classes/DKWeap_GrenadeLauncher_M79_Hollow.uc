class DKWeap_GrenadeLauncher_M79_Hollow extends KFWeap_GrenadeLauncher_M79;

// ===================================================================
// HOLLOW VARIANT — GrenadeLauncher_M79
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
	return "Breach Hollow";
}


defaultproperties
{
	Name="Default__DKWeap_GrenadeLauncher_M79_Hollow"
}
