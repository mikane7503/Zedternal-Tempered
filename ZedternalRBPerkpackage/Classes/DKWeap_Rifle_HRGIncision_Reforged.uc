class DKWeap_Rifle_HRGIncision_Reforged extends KFWeap_Rifle_HRGIncision;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=179
	InstantHitDamage(BASH_FIREMODE)=72
	InstantHitDamage(DEFAULT_FIREMODE)=945
	MagazineCapacity(0)=4
	SpareAmmoCapacity(0)=96
	AmmoPickupScale(0)=1.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_HRGIncisionHeal_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_HRGIncisionHurt_Reforged'
}
