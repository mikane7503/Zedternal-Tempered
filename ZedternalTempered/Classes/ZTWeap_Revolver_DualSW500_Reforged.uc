class ZTWeap_Revolver_DualSW500_Reforged extends KFWeap_Revolver_DualSW500;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=378
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=378
	MagazineCapacity(0)=35
	SpareAmmoCapacity(0)=233
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_RevolverSW500_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_RevolverSW500_Reforged'
	SingleClass=class'ZedternalTempered.ZTWeap_Revolver_SW500_Reforged'
}
