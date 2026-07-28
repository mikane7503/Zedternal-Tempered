class DKWeap_Pistol_DualColt1911_Reforged extends KFWeap_Pistol_DualColt1911;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=119
	InstantHitDamage(BASH_FIREMODE)=58
	InstantHitDamage(DEFAULT_FIREMODE)=119
	MagazineCapacity(0)=56
	SpareAmmoCapacity(0)=315
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_PistolColt1911_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_PistolColt1911_Reforged'
	SingleClass=class'ZedternalRBPerkpackage.DKWeap_Pistol_Colt1911_Reforged'
}
