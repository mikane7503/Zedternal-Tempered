class DKDT_FreezeExplosion extends WMDT_FreezeExplosion
    abstract
    hidedropdown;

defaultproperties
{
    bAnyPerk=True
    bNoPain=True
    bIgnoreSelfInflictedScale=True
    
    // High freeze power for instant freeze effect
    FreezePower=500.0f
    
    // Ensure proper knockout and impact effects
    MeleeHitPower=150
    KDeathVel=400
    
    Name="Default__DKDT_FreezeExplosion"
}