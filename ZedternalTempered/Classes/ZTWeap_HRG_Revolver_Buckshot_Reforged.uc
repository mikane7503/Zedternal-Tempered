class ZTWeap_HRG_Revolver_Buckshot_Reforged extends KFWeap_HRG_Revolver_Buckshot;

defaultproperties
{
	InstantHitDamage(BASH_FIREMODE)=56
	InstantHitDamage(DEFAULT_FIREMODE)=77
	MagazineCapacity(0)=18
	SpareAmmoCapacity(0)=208
	AmmoPickupScale(0)=1
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_Pellet_Reforged'
	DualClass=class'ZedternalTempered.ZTWeap_HRG_Revolver_DualBuckshot_Reforged'
}
