class DKWeap_AssaultRifle_Thompson_Reforged extends KFWeap_AssaultRifle_Thompson;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=72
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=72
	MagazineCapacity(0)=175
	SpareAmmoCapacity(0)=613
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
}
