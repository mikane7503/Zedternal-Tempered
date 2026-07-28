class DKWeap_SMG_Medic_Reforged extends KFWeap_SMG_Medic;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=12
	InstantHitDamage(BASH_FIREMODE)=56
	InstantHitDamage(DEFAULT_FIREMODE)=47
	MagazineCapacity(0)=140
	SpareAmmoCapacity(0)=1176
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_HealingDart_MedicBase_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_AssaultRifle_Reforged'
}
