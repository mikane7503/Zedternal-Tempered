class DKProj_BileBomb extends ZRProj_BileBomb;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.BileBomb_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.BileBomb_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_BileBomb"
}
