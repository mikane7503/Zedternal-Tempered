class ZTWeap_HRG_Boomy_Hollow extends KFWeap_HRG_Boomy;

// ===================================================================
// HOLLOW VARIANT — HRG_Boomy
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
	return "Rupture Hymn";
}


defaultproperties
{
	Name="Default__ZTWeap_HRG_Boomy_Hollow"
}
