class DKWeap_Pistol_DualDeagle_Reforged extends KFWeap_Pistol_DualDeagle;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=215
	InstantHitDamage(BASH_FIREMODE)=58
	InstantHitDamage(DEFAULT_FIREMODE)=215
	MagazineCapacity(0)=49
	SpareAmmoCapacity(0)=242
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_PistolDeagle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_PistolDeagle_Reforged'
	SingleClass=class'ZedternalRBPerkpackage.DKWeap_Pistol_Deagle_Reforged'
}
