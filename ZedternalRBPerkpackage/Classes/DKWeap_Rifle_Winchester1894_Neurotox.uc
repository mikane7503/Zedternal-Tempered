class DKWeap_Rifle_Winchester1894_Neurotox extends KFWeap_Rifle_Winchester1894;
 
DefaultProperties
{
    InventorySize=4
 
    WeaponSelectTexture=Texture2D'ZedternalRBPerkpackage_Resources.Weapons.UI_WeaponSelect_WinchesterNeurotox'
 
    MagazineCapacity[0]=30
    SpareAmmoCapacity[0]=120
    InitialSpareMags[0]=6
     
    // DEFAULT_FIREMODE
	FireModeIconPaths(DEFAULT_FIREMODE)=Texture2D'ui_firemodes_tex.UI_FireModeSelect_BulletSingle'
	FiringStatesArray(DEFAULT_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(DEFAULT_FIREMODE)=EWFT_InstantHit
	WeaponProjectiles(DEFAULT_FIREMODE)=class'DKProj_Bullet_Winchester1894_Neurotox'
	InstantHitDamage(DEFAULT_FIREMODE)=60
	InstantHitDamageTypes(DEFAULT_FIREMODE)=class'DKDT_Toxic_NeurotoxinRounds'
	FireInterval(DEFAULT_FIREMODE)=0.4
	Spread(DEFAULT_FIREMODE)=0.007
	PenetrationPower(DEFAULT_FIREMODE)=1.5
	FireOffset=(X=25,Y=3.0,Z=-2.5)
 
	// ALT_FIREMODE
	FiringStatesArray(ALTFIRE_FIREMODE)=WeaponSingleFiring
	WeaponFireTypes(ALTFIRE_FIREMODE)=EWFT_None
 
    AssociatedPerkClasses(0)=class'KFPerk_Sharpshooter'
    AssociatedPerkClasses(1)=class'KFPerk_Survivalist'
}