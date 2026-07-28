class DKProj_BileBomb_Deluxe extends ZRProj_BileBomb_Deluxe;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.BileBomb_Deluxe_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.BileBomb_Deluxe_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_BileBomb_Deluxe"
}
