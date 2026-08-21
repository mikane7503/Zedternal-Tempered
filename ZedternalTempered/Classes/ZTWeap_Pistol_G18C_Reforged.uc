class ZTWeap_Pistol_G18C_Reforged extends KFWeap_Pistol_G18C;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=88
	InstantHitDamage(BASH_FIREMODE)=60
	InstantHitDamage(DEFAULT_FIREMODE)=88
	MagazineCapacity(0)=116
	SpareAmmoCapacity(0)=1132
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_G18c_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.DKProj_Bullet_G18C_Reforged'
	DualClass=class'ZedternalTempered.ZTWeap_Pistol_DualG18_Reforged'
}
