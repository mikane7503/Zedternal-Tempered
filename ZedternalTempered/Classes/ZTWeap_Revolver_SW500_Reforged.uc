class ZTWeap_Revolver_SW500_Reforged extends KFWeap_Revolver_SW500;

defaultproperties
{
	InstantHitDamage(BASH_FIREMODE)=56
	InstantHitDamage(DEFAULT_FIREMODE)=378
	MagazineCapacity(0)=18
	SpareAmmoCapacity(0)=245
	AmmoPickupScale(0)=1
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_RevolverSW500_Reforged'
	DualClass=class'ZedternalTempered.ZTWeap_Revolver_DualSW500_Reforged'
}
