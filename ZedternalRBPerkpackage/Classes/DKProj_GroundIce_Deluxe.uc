class DKProj_GroundIce_Deluxe extends ZRProj_GroundIce_Deluxe;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.GroundIce_Deluxe_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.GroundIce_Deluxe_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_GroundIce_Deluxe"
}
