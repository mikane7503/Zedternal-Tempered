class DKWeap_HRG_Warthog_Hollow extends KFWeap_HRG_Warthog;

// ===================================================================
// HOLLOW VARIANT — HRG_Warthog
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
	return "Maw of Cinders";
}


defaultproperties
{
	Name="Default__DKWeap_HRG_Warthog_Hollow"
}
