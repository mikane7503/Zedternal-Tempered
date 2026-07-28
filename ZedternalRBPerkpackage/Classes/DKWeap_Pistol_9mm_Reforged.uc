class DKWeap_Pistol_9mm_Reforged extends KFWeap_Pistol_9mm;

defaultproperties
{
	InstantHitDamage(BASH_FIREMODE)=47
	InstantHitDamage(DEFAULT_FIREMODE)=60
	MagazineCapacity(0)=53
	SpareAmmoCapacity(0)=184
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Pistol9mm_Reforged'
	DualClass=class'ZedternalRBPerkpackage.DKWeap_Pistol_Dual9mm_Reforged'
}
