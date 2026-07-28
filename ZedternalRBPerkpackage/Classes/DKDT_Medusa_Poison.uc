class DKDT_Medusa_Poison extends KFDT_Toxic
    abstract
    hidedropdown;

// Medusa's venomous poison damage type with proper per-tick damage configuration

defaultproperties
{
    bAnyPerk=True
    bStackDoT=False  // Medusa poison doesn't stack - resets duration instead
    
    // FIXED: Poison DoT configuration for proper per-tick damage
    DoT_Type=DOT_Toxic
    DoT_Duration=5.0f       // 5 seconds duration (matches perk's PoisonDuration)
    DoT_Interval=1.0f       // Damage every 1 second
    DoT_DamageScale=1.0f    // Full damage per tick (should be 2 damage per tick when applied correctly)
    
    // Poison visual and audio effects
    PoisonPower=15.0f       // Strength of poison effect for visuals
    
    // Impact effects
    StumblePower=20.0f      // Small stumble on poison application
    GunHitPower=0.0f        // No gun hit power for DoT
    
    // Damage impulse (minimal for poison)
    KDamageImpulse=0.0f
    
    Name="Default__DKDT_Medusa_Poison"
}