class DKWeap_Shotgun_Medic_Hollow extends KFWeap_Shotgun_Medic;

// ===================================================================
// HOLLOW VARIANT — Shotgun_Medic
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
	return "Maw of Absence";
}


defaultproperties
{
	Name="Default__DKWeap_Shotgun_Medic_Hollow"
}
