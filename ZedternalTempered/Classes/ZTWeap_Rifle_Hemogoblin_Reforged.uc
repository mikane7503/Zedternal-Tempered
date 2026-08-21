class ZTWeap_Rifle_Hemogoblin_Reforged extends KFWeap_Rifle_Hemogoblin;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=12
	InstantHitDamage(BASH_FIREMODE)=65
	InstantHitDamage(DEFAULT_FIREMODE)=284
	MagazineCapacity(0)=25
	SpareAmmoCapacity(0)=275
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_HealingDart_MedicBase_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_Hemogoblin_Reforged'
}
