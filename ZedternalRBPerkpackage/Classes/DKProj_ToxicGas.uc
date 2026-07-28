class DKProj_ToxicGas extends ZRProj_ToxicGas;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.ToxicGas_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.ToxicGas_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_ToxicGas"
}
