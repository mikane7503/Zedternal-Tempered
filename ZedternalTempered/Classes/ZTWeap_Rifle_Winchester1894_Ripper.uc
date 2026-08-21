class ZTWeap_Rifle_Winchester1894_Ripper extends KFWeap_Rifle_Winchester1894;

defaultproperties
{
	MagazineCapacity(0)=32
	AmmoPickupScale(0)=0.5
	SpareAmmoCapacity(0)=180
	InstantHitDamage(BASH_FIREMODE)=34
	InstantHitDamage(DEFAULT_FIREMODE)=120
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_Winchester1894_Ripper'
	Name="Default__ZTWeap_Rifle_Winchester1894_Ripper"
}