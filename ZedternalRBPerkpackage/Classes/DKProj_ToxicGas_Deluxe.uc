class DKProj_ToxicGas_Deluxe extends ZRProj_ToxicGas_Deluxe;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.ToxicGas_Deluxe_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.ToxicGas_Deluxe_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_ToxicGas_Deluxe"
}
