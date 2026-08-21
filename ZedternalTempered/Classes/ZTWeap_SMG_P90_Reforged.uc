class ZTWeap_SMG_P90_Reforged extends KFWeap_SMG_P90;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=72
	InstantHitDamage(BASH_FIREMODE)=60
	InstantHitDamage(DEFAULT_FIREMODE)=72
	MagazineCapacity(0)=175
	SpareAmmoCapacity(0)=858
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
}
