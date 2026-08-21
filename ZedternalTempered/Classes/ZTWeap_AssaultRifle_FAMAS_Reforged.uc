class ZTWeap_AssaultRifle_FAMAS_Reforged extends KFWeap_AssaultRifle_FAMAS;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=72
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=84
	MagazineCapacity(0)=105
	MagazineCapacity(1)=21
	SpareAmmoCapacity(0)=588
	SpareAmmoCapacity(1)=89
	AmmoPickupScale(0)=0.5
	AmmoPickupScale(1)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_Pellet_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
}
