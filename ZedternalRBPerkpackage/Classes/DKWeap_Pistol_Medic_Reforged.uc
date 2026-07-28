class DKWeap_Pistol_Medic_Reforged extends KFWeap_Pistol_Medic;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=12
	InstantHitDamage(BASH_FIREMODE)=51
	InstantHitDamage(DEFAULT_FIREMODE)=47
	MagazineCapacity(0)=53
	SpareAmmoCapacity(0)=588
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_HealingDart_MedicBase_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Pistol9mm_Reforged'
}
