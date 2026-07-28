class DKProj_GroundIce extends ZRProj_GroundIce;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.GroundIce_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.GroundIce_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_GroundIce"
}
