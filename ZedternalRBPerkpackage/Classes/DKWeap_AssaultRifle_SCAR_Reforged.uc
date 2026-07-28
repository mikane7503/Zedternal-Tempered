class DKWeap_AssaultRifle_SCAR_Reforged extends KFWeap_AssaultRifle_SCAR;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=131
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=131
	MagazineCapacity(0)=70
	SpareAmmoCapacity(0)=833
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
}
