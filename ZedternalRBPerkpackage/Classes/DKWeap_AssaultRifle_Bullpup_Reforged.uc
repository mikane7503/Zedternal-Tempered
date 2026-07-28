class DKWeap_AssaultRifle_Bullpup_Reforged extends KFWeap_AssaultRifle_Bullpup;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=77
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=77
	MagazineCapacity(0)=105
	SpareAmmoCapacity(0)=662
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
}
