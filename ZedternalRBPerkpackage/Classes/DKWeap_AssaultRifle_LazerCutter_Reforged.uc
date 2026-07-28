class DKWeap_AssaultRifle_LazerCutter_Reforged extends KFWeap_AssaultRifle_LazerCutter;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=95
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=131
	MagazineCapacity(0)=175
	SpareAmmoCapacity(0)=1103
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_LazerCutter_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_LazerCutter_Reforged'
}
