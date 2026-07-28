class DKWeap_AssaultRifle_Medic_Reforged extends KFWeap_AssaultRifle_Medic;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=12
	InstantHitDamage(BASH_FIREMODE)=65
	InstantHitDamage(DEFAULT_FIREMODE)=84
	MagazineCapacity(0)=140
	SpareAmmoCapacity(0)=980
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_HealingDart_MedicBase_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
}
