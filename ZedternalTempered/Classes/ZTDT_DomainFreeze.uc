// ===================================================================
// ZTDT_DomainFreeze - cryo damage type for the Domain "Stasis" ability.
//
// Carries FreezePower=100 so a single hit freezes a non-boss zed solid,
// mirroring ZR's WMDT_FreezeExplosion. Damage is negligible; the freeze
// is the point. Bosses cannot perform SM_Frozen, so this is a no-op on
// them (the ability also guards with IsABoss()).
// ===================================================================
class ZTDT_DomainFreeze extends KFDT_Freeze_FreezeGrenade abstract hidedropdown;

defaultproperties
{
	bAnyPerk=True
	bNoPain=True
	bIgnoreSelfInflictedScale=True

	FreezePower=100.0f

	Name="Default__ZTDT_DomainFreeze"
}
