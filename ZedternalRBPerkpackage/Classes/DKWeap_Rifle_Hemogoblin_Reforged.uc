class DKWeap_Rifle_Hemogoblin_Reforged extends KFWeap_Rifle_Hemogoblin;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=12
	InstantHitDamage(BASH_FIREMODE)=65
	InstantHitDamage(DEFAULT_FIREMODE)=284
	MagazineCapacity(0)=25
	SpareAmmoCapacity(0)=275
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_HealingDart_MedicBase_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalRBPerkpackage.DKProj_Bullet_Hemogoblin_Reforged'
}
