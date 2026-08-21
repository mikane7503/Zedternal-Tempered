class ZTWeap_AssaultRifle_HRGIncendiaryRifle_Reforged extends WMWeap_AssaultRifle_HRGIncendiaryRifle;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=544
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=72
	MagazineCapacity(0)=105
	MagazineCapacity(1)=4
	SpareAmmoCapacity(0)=662
	SpareAmmoCapacity(1)=23
	AmmoPickupScale(0)=0.5
	AmmoPickupScale(1)=1
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Grenade_HRGIncendiaryRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_HRGIncendiaryRifle_Reforged'
}
