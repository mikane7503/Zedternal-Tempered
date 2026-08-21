class ZTWeap_Shotgun_Medic_Reforged extends KFWeap_Shotgun_Medic;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=12
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=60
	MagazineCapacity(0)=35
	SpareAmmoCapacity(0)=221
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_HealingDart_MedicBase_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_Pellet_Reforged'
}
