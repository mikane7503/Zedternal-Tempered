class ZTWeap_AssaultRifle_MedicRifleGrenadeLauncher_Reforged extends WMWeap_AssaultRifle_MedicRifleGrenadeLauncher;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=119
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=112
	MagazineCapacity(0)=105
	MagazineCapacity(1)=4
	SpareAmmoCapacity(0)=515
	SpareAmmoCapacity(1)=23
	AmmoPickupScale(0)=0.5
	AmmoPickupScale(1)=1
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_MedicGrenade_Mini_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
}
