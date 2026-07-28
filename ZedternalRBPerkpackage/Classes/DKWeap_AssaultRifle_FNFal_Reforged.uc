class DKWeap_AssaultRifle_FNFal_Reforged extends KFWeap_AssaultRifle_FNFal;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=166
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=166
	MagazineCapacity(0)=70
	SpareAmmoCapacity(0)=392
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
}
