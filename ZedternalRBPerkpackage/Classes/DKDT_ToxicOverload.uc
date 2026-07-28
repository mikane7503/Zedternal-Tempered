// DamageType for Toxic Overload explosion.
// Deals toxic AoE damage with poison DoT on hit.
class DKDT_ToxicOverload extends KFDT_Toxic
	abstract
	hidedropdown;

defaultproperties
{
	bAnyPerk=True
	bStackDoT=True

	DoT_Type=DOT_Toxic
	DoT_Duration=5.0f
	DoT_Interval=1.0f
	DoT_DamageScale=0.5f

	StumblePower=0.0f
	GunHitPower=0.0f
	BleedPower=0.0f

	KDeathUpKick=200.0f
	KDeathVel=250.0f
	KDamageImpulse=500.0f

	Name="Default__DKDT_ToxicOverload"
}
