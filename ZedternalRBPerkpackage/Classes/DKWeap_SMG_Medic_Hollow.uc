class DKWeap_SMG_Medic_Hollow extends KFWeap_SMG_Medic;

// ===================================================================
// HOLLOW VARIANT — SMG_Medic
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
	return "Pulse Void";
}


defaultproperties
{
	Name="Default__DKWeap_SMG_Medic_Hollow"
}
