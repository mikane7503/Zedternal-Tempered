class ZTProj_FreezeExplosion extends WMProj_FreezeExplosion;

// Immediate explosion like the WM example
simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    ExplodeTimer();
}

defaultproperties
{
    AssociatedPerkClass=class'ZedternalReborn.WMPerk'
    FuseTime=0.05f
    
    // Explosion template with high freeze power and large radius
    Begin Object Name=ExploTemplate0
        Damage=75.0f
        DamageRadius=2000.0f  // 20 meters
        MyDamageType=class'ZedternalTempered.ZTDT_FreezeExplosion'
        ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
        
        // Visual and audio effects
        ExplosionEffects=KFImpactEffectInfo'WEP_Freeze_Grenade_Arch.FreezeGrenade_Explosion'
        ExplosionSound=AkEvent'WW_WEP_Freeze_Grenade.Play_Freeze_Grenade_Explo'
        
        // Camera shake for dramatic effect
        CamShakeInnerRadius=400
        CamShakeOuterRadius=2000
        CamShakeFalloff=1.5f
    End Object
    
    Name="Default__ZTProj_FreezeExplosion"
}