class DKWeap_Rifle_ParasiteImplanter_Reforged extends KFWeap_Rifle_ParasiteImplanter;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=4
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=651
	MagazineCapacity(0)=21
	SpareAmmoCapacity(0)=193
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_ParasiteImplanterAlt_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_ParasiteImplanter_Reforged'
}
