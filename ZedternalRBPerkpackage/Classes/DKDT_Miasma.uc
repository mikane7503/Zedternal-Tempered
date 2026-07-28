// Custom toxic DoT for the Miasma aura.
//
// bStackDoT=True makes KFPawn.ApplyDamageOverTime skip the shared DOT_Toxic slot
// lookup, so Miasma stacks as independent entries instead of losing the slot to the
// long-duration Neurotoxin DoT (which it could never out-total). The short 3s
// duration against the helper's 1s re-apply self-caps the stack count at ~3.
//
// The helper passes a per-tick damage already computed as a fraction of the zed's
// max health, so DoT_DamageScale stays 1.0. Still a KFDT_Toxic child, so toxic
// resistance applies and these stacks satisfy ZedHasToxicDoT -- Miasma keeps
// enabling Necrosis / Putrefaction / Adaptive Venom while now dealing real damage.
class DKDT_Miasma extends KFDT_Toxic
	abstract
	hidedropdown;

defaultproperties
{
	bAnyPerk=True
	bStackDoT=True

	DoT_Type=DOT_Toxic
	DoT_Duration=3.0f
	DoT_Interval=1.0f
	DoT_DamageScale=1.0f

	KDamageImpulse=0

	Name="Default__DKDT_Miasma"
}
