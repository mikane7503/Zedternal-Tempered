// ===================================================================
// ZTDT_Siphon - Parasite Life-Drain Damage Type
// Uses DOT_Bleeding for visual effect, tracked separately by Helper
// ===================================================================
class ZTDT_Siphon extends KFDT_Bleeding abstract hidedropdown;

defaultproperties
{
	bAnyPerk=True

	// Uses bleeding visual effect
	DoT_Type=DOT_Bleeding
	DoT_Duration=4.0f
	DoT_Interval=1.0f
	DoT_DamageScale=0.3f

	// Moderate stumble, strong bleed effect
	StumblePower=15.0f
	GunHitPower=0.0f
	BleedPower=35.0f

	KDamageImpulse=0.0f

	Name="Default__ZTDT_Siphon"
}
