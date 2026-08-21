class ZTWeap_AssaultRifle_HRGTeslauncher_Reforged extends WMWeap_AssaultRifle_HRGTeslauncher;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=119
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=161
	MagazineCapacity(0)=105
	MagazineCapacity(1)=4
	SpareAmmoCapacity(0)=588
	SpareAmmoCapacity(1)=18
	AmmoPickupScale(0)=0.5
	AmmoPickupScale(1)=1
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Grenade_HRGTeslauncher_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_HRGTeslauncher_Reforged'
}
