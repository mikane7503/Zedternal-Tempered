class DKWeap_AssaultRifle_AK12_Reforged extends KFWeap_AssaultRifle_AK12;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=95
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=95
	MagazineCapacity(0)=105
	SpareAmmoCapacity(0)=735
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
}
