class DKProj_BleedNailBombGrenade extends ZRProj_BleedNailBombGrenade;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.BleedNailBomb_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.BleedNailBomb_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_BleedNailBombGrenade"
}
