class ZTWeap_HRG_SonicGun_Reforged extends KFWeap_HRG_SonicGun;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=296
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=296
	MagazineCapacity(0)=35
	SpareAmmoCapacity(0)=221
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_SonicBlastFullyCharged_HRG_SonicGun_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_SonicBlastUncharged_HRG_SonicGun_Reforged'
}
