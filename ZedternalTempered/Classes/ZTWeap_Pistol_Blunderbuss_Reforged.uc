class ZTWeap_Pistol_Blunderbuss_Reforged extends KFWeap_Pistol_Blunderbuss;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=119
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=709
	MagazineCapacity(0)=11
	SpareAmmoCapacity(0)=96
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Nail_Blunderbuss_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Cannonball_Blunderbuss_Reforged'
}
