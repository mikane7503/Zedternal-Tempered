class DKWeap_HRG_Revolver_DualBuckshot_Reforged extends KFWeap_HRG_Revolver_DualBuckshot;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=77
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=77
	MagazineCapacity(0)=35
	SpareAmmoCapacity(0)=196
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Pellet_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Pellet_Reforged'
	SingleClass=class'ZedternalRBPerkpackage.DKWeap_HRG_Revolver_Buckshot_Reforged'
}
