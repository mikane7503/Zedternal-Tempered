// ===================================================================
// ZTDT_InfernoBlast - Custom Fire DoT for Inferno Ability
// High damage, long duration fire effect
// ===================================================================
class ZTDT_InfernoBlast extends KFDT_Fire abstract;

defaultproperties
{
	bAnyPerk=True
	
	DoT_Duration=10.0f
	DoT_Interval=0.5f
	DoT_DamageScale=3.0f
	
	StumblePower=5.0f
	BurnPower=30.0f
	MicrowavePower=10.0f
	
	Name="Default__ZTDT_InfernoBlast"
}
