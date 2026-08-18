// ===================================================================
// DKProj_Goalkeeper_Return - The returned catch
// A player-owned husk fireball hurled back at the zeds. Explosion uses
// DKDT_Goalkeeper_Return so DKUpgrade_Perk_Goalkeeper.ModifyDamageGiven
// can scale it per perk level (no runtime template mutation - the
// archetype is shared, so damage scaling MUST go through the DT gate).
// Pattern reference: WMProj_Husk_Fireball_Suicide (ZR).
// ===================================================================
class DKProj_Goalkeeper_Return extends KFProj_Husk_Fireball;

simulated function Tick(float Delta)
{
	SetRotation(rotator(Velocity));
	super.Tick(Delta);
}

defaultproperties
{
	Speed=2600.0f
	MaxSpeed=2600.0f

	BurnDuration=2.0f
	BurnDamageInterval=0.5f

	Begin Object Name=ExploTemplate0
		Damage=150.0f
		DamageRadius=300.0f
		MyDamageType=class'ZedternalRBPerkpackage.DKDT_Goalkeeper_Return'
	End Object

	Name="Default__DKProj_Goalkeeper_Return"
}
