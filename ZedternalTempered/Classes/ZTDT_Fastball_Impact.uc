// ===================================================================
// ZTDT_Fastball_Impact - Landing shockwave of a launched teammate
// Dealt via HurtRadius from ZTUpgrade_Perk_Fastball_Helper, credited
// to the LAUNCHER. Scaled per perk level in
// ZTUpgrade_Perk_Fastball.ModifyDamageGiven (gates on this class).
// High stumble so landings visibly scatter the horde; knockdown at
// close range comes from raw damage + stumble stacking.
// ===================================================================
class ZTDT_Fastball_Impact extends KFDT_Explosive;

defaultproperties
{
	bCausedByWorld=False
	bArmorStops=True
	bAnyPerk=True

	KnockdownPower=40.0f
	StumblePower=200.0f
	GunHitPower=0.0f

	RadialDamageImpulse=2000.0f
	bExtraMomentumZ=True
}
