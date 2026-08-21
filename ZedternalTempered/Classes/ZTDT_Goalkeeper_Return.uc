// ===================================================================
// ZTDT_Goalkeeper_Return - Damage type for returned (caught) projectiles
// Fired by ZTProj_Goalkeeper_Return. Damage is scaled per perk level in
// ZTUpgrade_Perk_Goalkeeper.ModifyDamageGiven (gates on this class).
// ===================================================================
class ZTDT_Goalkeeper_Return extends KFDT_Fire;

defaultproperties
{
	bCausedByWorld=False
	bArmorStops=True
	bAnyPerk=True

	DoT_Type=DOT_Fire
	DoT_Duration=3.0f
	DoT_Interval=0.5f
	DoT_DamageScale=0.3f

	BurnPower=20.0f
	StumblePower=25.0f

	ModifierPerkList(0)=class'KFPerk_Firebug'
}
