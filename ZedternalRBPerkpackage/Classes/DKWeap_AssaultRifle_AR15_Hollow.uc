class DKWeap_AssaultRifle_AR15_Hollow extends KFWeap_AssaultRifle_AR15;

// ===================================================================
// HOLLOW VARIANT — AssaultRifle_AR15
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
	return "Bone Whisper Caliber";
}


defaultproperties
{
	Name="Default__DKWeap_AssaultRifle_AR15_Hollow"
}
