// ===================================================================
// ZTDT_DomainEMP - EMP + stun damage type for the Domain "Tempest"
// ability.
//
// EMP power disrupts Husks / Sirens / cloaked Stalkers and other
// specials; StunPower stuns trash. Damage is negligible. Bosses resist
// EMP and stun naturally, so Tempest mainly disables the supporting cast.
// ===================================================================
class ZTDT_DomainEMP extends KFDT_EMP abstract hidedropdown;

defaultproperties
{
	bAnyPerk=True
	bNoPain=True
	bIgnoreSelfInflictedScale=True

	EMPPower=100.0f
	StunPower=500.0f

	Name="Default__ZTDT_DomainEMP"
}
