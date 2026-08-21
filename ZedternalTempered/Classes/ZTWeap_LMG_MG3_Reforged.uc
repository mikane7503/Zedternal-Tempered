class ZTWeap_LMG_MG3_Reforged extends KFWeap_LMG_MG3;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=37
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=84
	MagazineCapacity(0)=263
	SpareAmmoCapacity(0)=1286
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_MG3_Alt_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
}
