class DKWeap_Pistol_Dual9mm_Reforged extends KFWeap_Pistol_Dual9mm;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=60
	InstantHitDamage(BASH_FIREMODE)=53
	InstantHitDamage(DEFAULT_FIREMODE)=60
	MagazineCapacity(0)=105
	SpareAmmoCapacity(0)=147
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Pistol9mm_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Pistol9mm_Reforged'
	SingleClass=class'ZedternalRBPerkpackage.DKWeap_Pistol_9mm_Reforged'
}
