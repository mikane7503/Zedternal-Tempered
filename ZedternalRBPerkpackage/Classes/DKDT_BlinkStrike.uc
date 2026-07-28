// Devastating melee strike dealt by the Speedster's Blink Strike flurry.
//
// The helper computes the actual damage amount (a % of the target's max health,
// see DKUpgrade_Perk_Speedster_Helper) and passes it to TakeDamage with this
// type, so there is no DoT or scale here -- it is a single instant melee hit.
// Extends KFDT_Slashing so it reads as a melee/slash hit for gore, hit
// reactions and the melee VFX. High impulse for a satisfying ragdoll fling.
class DKDT_BlinkStrike extends KFDT_Slashing
	abstract
	hidedropdown;

defaultproperties
{
	bAnyPerk=True

	KDamageImpulse=3000
	KDeathUpKick=400
	KDeathVel=400

	Name="Default__DKDT_BlinkStrike"
}
