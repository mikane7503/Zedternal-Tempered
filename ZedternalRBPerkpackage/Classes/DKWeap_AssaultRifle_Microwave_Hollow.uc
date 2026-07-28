class DKWeap_AssaultRifle_Microwave_Hollow extends KFWeap_AssaultRifle_Microwave;

// ===================================================================
// HOLLOW VARIANT — AssaultRifle_Microwave
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
	return "Rift Scorcher";
}


defaultproperties
{
	Name="Default__DKWeap_AssaultRifle_Microwave_Hollow"
}
