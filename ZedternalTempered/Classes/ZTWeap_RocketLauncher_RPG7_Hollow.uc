class ZTWeap_RocketLauncher_RPG7_Hollow extends KFWeap_RocketLauncher_RPG7;

// ===================================================================
// HOLLOW VARIANT — RocketLauncher_RPG7
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
	return "Rift Maw";
}


defaultproperties
{
	Name="Default__ZTWeap_RocketLauncher_RPG7_Hollow"
}
