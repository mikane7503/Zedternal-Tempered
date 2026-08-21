class ZTWeap_SMG_MP5RAS_Reforged extends KFWeap_SMG_MP5RAS;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=60
	InstantHitDamage(BASH_FIREMODE)=58
	InstantHitDamage(DEFAULT_FIREMODE)=60
	MagazineCapacity(0)=140
	SpareAmmoCapacity(0)=784
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
}
