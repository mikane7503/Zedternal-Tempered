class ZTWeap_RocketLauncher_ThermiteBore_Hollow extends KFWeap_RocketLauncher_ThermiteBore;

// ===================================================================
// HOLLOW VARIANT — RocketLauncher_ThermiteBore
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
	return "Cinder Rift";
}


defaultproperties
{
	Name="Default__ZTWeap_RocketLauncher_ThermiteBore_Hollow"
}
