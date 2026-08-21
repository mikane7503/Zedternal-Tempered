// ===================================================================
// ZTDT_InfestedRounds
// Damage type for the Infested Rounds skill AoE burst.
// Used as a marker to prevent recursive explosion chains.
// ===================================================================
class ZTDT_InfestedRounds extends KFDT_Toxic abstract hidedropdown;

defaultproperties
{
	bAnyPerk=True

	DoT_Type=DOT_Bleeding
	DoT_Duration=3.0f
	DoT_Interval=1.0f
	DoT_DamageScale=0.25f

	StumblePower=0.0f
	GunHitPower=0.0f
	BleedPower=50.0f

	KDeathUpKick=200.0f
	KDeathVel=250.0f
	KDamageImpulse=500.0f

	Name="Default__ZTDT_InfestedRounds"
}
