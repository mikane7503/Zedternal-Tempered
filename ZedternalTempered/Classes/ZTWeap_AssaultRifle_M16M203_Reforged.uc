class ZTWeap_AssaultRifle_M16M203_Reforged extends WMWeap_AssaultRifle_M16M203;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=544
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=79
	MagazineCapacity(0)=105
	MagazineCapacity(1)=4
	SpareAmmoCapacity(0)=662
	SpareAmmoCapacity(1)=33
	AmmoPickupScale(0)=0.5
	AmmoPickupScale(1)=1
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_HighExplosive_M16M203_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
}
