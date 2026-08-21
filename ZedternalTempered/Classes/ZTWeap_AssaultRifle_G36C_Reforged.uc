class ZTWeap_AssaultRifle_G36C_Reforged extends KFWeap_AssaultRifle_G36C;

defaultproperties
{
	InstantHitDamage(ALTFIRE_FIREMODE)=107
	InstantHitDamage(BASH_FIREMODE)=63
	InstantHitDamage(DEFAULT_FIREMODE)=107
	MagazineCapacity(0)=105
	SpareAmmoCapacity(0)=1103
	AmmoPickupScale(0)=0.5
	WeaponProjectiles(ALTFIRE_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
	WeaponProjectiles(DEFAULT_FIREMODE)=class'ZedternalTempered.ZTProj_Bullet_AssaultRifle_Reforged'
}
