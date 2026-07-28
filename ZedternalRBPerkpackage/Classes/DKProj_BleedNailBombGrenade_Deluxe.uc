class DKProj_BleedNailBombGrenade_Deluxe extends ZRProj_BleedNailBombGrenade_Deluxe;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if (Role == Role_Authority)
	{
		ExplosionTemplate.Damage = class'DKConfig_HowdyProjectiles'.default.BleedNailBomb_Deluxe_Damage;
		ExplosionTemplate.DamageRadius = class'DKConfig_HowdyProjectiles'.default.BleedNailBomb_Deluxe_Radius;
	}
}

defaultproperties
{
	Name="Default__DKProj_BleedNailBombGrenade_Deluxe"
}
