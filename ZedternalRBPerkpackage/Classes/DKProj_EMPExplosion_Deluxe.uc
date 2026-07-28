class DKProj_EMPExplosion_Deluxe extends ZRProj_EMPExplosion_Deluxe;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.EMPExplosion_Deluxe_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.EMPExplosion_Deluxe_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_EMPExplosion_Deluxe"
}
