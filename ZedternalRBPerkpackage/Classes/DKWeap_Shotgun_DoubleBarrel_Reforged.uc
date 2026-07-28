class DKWeap_Shotgun_DoubleBarrel_Reforged extends KFWeap_Shotgun_DoubleBarrel;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=60
	InstantHitDamage(BASH_FIREMODE)=58
	InstantHitDamage(DEFAULT_FIREMODE)=60
	MagazineCapacity(0)=7
	SpareAmmoCapacity(0)=114
	AmmoPickupScale(0)=1.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Pellet_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Pellet_Reforged'
}
