class DKWeap_AssaultRifle_Microwave_Reforged extends KFWeap_AssaultRifle_Microwave;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=119
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=119
	MagazineCapacity(0)=140
	SpareAmmoCapacity(0)=784
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_MicrowaveRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_MicrowaveRifle_Reforged'
}
