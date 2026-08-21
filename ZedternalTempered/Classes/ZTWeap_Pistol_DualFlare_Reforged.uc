class ZTWeap_Pistol_DualFlare_Reforged extends KFWeap_Pistol_DualFlare;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=95
	InstantHitDamage(BASH_FIREMODE)=58
	InstantHitDamage(DEFAULT_FIREMODE)=95
	MagazineCapacity(0)=42
	SpareAmmoCapacity(0)=441
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_FlareGun_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_FlareGun_Reforged'
	SingleClass=class'ZedternalTempered.ZTWeap_Pistol_Flare_Reforged'
}
