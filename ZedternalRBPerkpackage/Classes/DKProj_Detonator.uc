// ===================================================================
// DKProj_Detonator - Dynamic-radius explosive projectile for the
// Detonator perk's active-window detonations.
//
// Spawned at the dying zed's location during the Detonator's active
// window. The caller sets DamageOverride / RadiusOverride after Spawn
// returns; the FuseTime delay (100 ms) gives the caller time to write
// those values before the explosion fires.
//
// The Explode() override applies the runtime overrides to the
// ExplosionTemplate before Super.Explode() reads them.
//
// Self-damage is filtered: ActorClassToIgnoreForDamage is set to
// KFPawn_Human, so the player is never harmed by their own perk.
// ===================================================================
class DKProj_Detonator extends KFProj_FragGrenade
    hidedropdown;

var float DamageOverride;       // applied to ExplosionTemplate.Damage in Explode
var float RadiusOverride;       // applied to ExplosionTemplate.DamageRadius in Explode

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    // Sit-in-place: the perk spawns this at the dying zed's location
    // and we want it to detonate there, not bounce around.
    if (Role == Role_Authority)
    {
        Velocity = vect(0,0,0);
        SetPhysics(PHYS_None);
    }
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    // Apply runtime overrides set by the caller after Spawn returns.
    if (Role == Role_Authority && ExplosionTemplate != None)
    {
        if (DamageOverride > 0.0f)
            ExplosionTemplate.Damage = DamageOverride;
        if (RadiusOverride > 0.0f)
            ExplosionTemplate.DamageRadius = RadiusOverride;
    }
    Super.Explode(HitLocation, HitNormal);
}

defaultproperties
{
    AssociatedPerkClass=class'ZedternalReborn.WMPerk'

    // 100 ms grace window for caller to write DamageOverride / RadiusOverride
    // after Spawn returns. KFProjectile.PostBeginPlay sets the explode timer
    // for us; we just need this to be > 0.
    FuseTime=0.1f

    // Make sure the projectile sits exactly where it spawned.
    Speed=0.0f
    MaxSpeed=0.0f
    TerminalVelocity=0.0f
    TossZ=0.0f

    // Override the parent's Frag explosion template: damage / radius are
    // placeholder defaults; the helper overrides them per spawn. Player
    // is filtered out of the damage list so self-damage never triggers.
    Begin Object Name=ExploTemplate0
        Damage=400.0f
        DamageRadius=300.0f
        ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'
    End Object

    Name="Default__DKProj_Detonator"
}
