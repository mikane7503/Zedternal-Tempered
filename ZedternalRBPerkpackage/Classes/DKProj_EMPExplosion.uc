class DKProj_EMPExplosion extends ZRProj_EMPExplosion;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.EMPExplosion_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.EMPExplosion_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_EMPExplosion"
}
