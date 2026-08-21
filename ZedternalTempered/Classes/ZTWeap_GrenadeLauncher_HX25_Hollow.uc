class ZTWeap_GrenadeLauncher_HX25_Hollow extends KFWeap_GrenadeLauncher_HX25;

// ===================================================================
// HOLLOW VARIANT — GrenadeLauncher_HX25
//
// This is a Hollow weapon variant. It extends the base weapon directly.
// Stat bonuses are applied through ZTUpgrade_Perk_Hollow's ModifyXXX
// functions using ZTHollowWeaponData for bonus values.
//
// - BuyPrice: 0 (free once unlocked)
// - Not eligible for weapon upgrades
// - Only visible to the player who completed all 5 conditions
// ===================================================================


simulated function string GetHumanReadableName()
{
	return "Void Seed";
}


defaultproperties
{
	Name="Default__ZTWeap_GrenadeLauncher_HX25_Hollow"
}
