class DKWeap_AutoTurret_Reforged extends WMWeap_AutoTurret;

// AutoTurret deploys a pawn - it has no thrown KFProjectile, so the inherited
// KFWeap_ThrownBase version dereferences a None ProjClass ("Accessed null class
// context 'ProjClass'"). Delegate to the turret gun's own trader-damage calc,
// which reports the correct value for its fire type (hitscan or projectile).
static simulated function float CalculateTraderWeaponStatDamage()
{
	if (default.TurretWeapon != none)
		return default.TurretWeapon.static.CalculateTraderWeaponStatDamage();

	return 0.f;
}

defaultproperties
{
	InstantHitDamage(BASH_FIREMODE)=63
	SpareAmmoCapacity(0)=14
}
