class ZTWeap_HRG_CranialPopper_Reforged extends KFWeap_HRG_CranialPopper;

defaultproperties
{
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=119
	MagazineCapacity(0)=25
	SpareAmmoCapacity(0)=275
	AmmoPickupScale(0)=1
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Grenade_HRG_CranialPopper_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_HRG_CranialPopper_Reforged'
}
