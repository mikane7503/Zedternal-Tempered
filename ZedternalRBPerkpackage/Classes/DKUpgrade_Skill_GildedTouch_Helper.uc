// ===================================================================
// DKUpgrade_Skill_GildedTouch_Helper — Forge Detonation Spawner
//
// Spawns a scaled AoE explosion at the killed zed's location.
// Damage and radius are pre-calculated by the main skill class
// based on mastery milestones. Uses KFExplosionActorReplicated
// with a KFGameExplosion template sub-object.
//
// Follows the SacrificeExplode / FP Omega explosion pattern:
//   Spawn ExploActor → configure → Explode(template)
//
// Explosion does NOT damage the owning player.
// Kills from the explosion are attributed to the player.
//
// Sound: Plays 'Artificer_Gilded_Touch' on detonation via DKSoundManager.
// ===================================================================
class DKUpgrade_Skill_GildedTouch_Helper extends Info;

var int UpgradeLevel;
var KFPawn_Human Player;

// Explosion template (sub-object, modified before each Explode() call)
var KFGameExplosion ForgeExplosionTemplate;

// Brief cooldown to prevent explosion spam from multi-hit kills
var float LastDetonationTime;
var const float DetonationCooldown;

// ===================================================================
// INITIALIZATION
// ===================================================================

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    LastDetonationTime = 0.f;
}

// ===================================================================
// FORGE DETONATION — Spawn a scaled explosion at the zed's location
// Called from DKUpgrade_Skill_GildedTouch.ModifyDamageGiven
// ===================================================================

function TriggerForgeDetonation(KFPawn_Monster KilledZed, float ScaledDamage, float ScaledRadius)
{
    local KFExplosionActorReplicated ExploActor;
    local vector ExploLocation;
    local float CurrentTime;

    if (Player == None || Player.Controller == None || KilledZed == None)
        return;

    // Brief cooldown check
    CurrentTime = WorldInfo.TimeSeconds;
    if ((CurrentTime - LastDetonationTime) < DetonationCooldown)
        return;
    LastDetonationTime = CurrentTime;

    // Set explosion location at the killed zed's feet
    ExploLocation = KilledZed.Location;

    // Scale the template for this detonation
    ForgeExplosionTemplate.Damage = ScaledDamage;
    ForgeExplosionTemplate.DamageRadius = ScaledRadius;

    // Spawn replicated explosion actor
    ExploActor = Player.Spawn(class'KFExplosionActorReplicated', Player, , ExploLocation, , , True);
    if (ExploActor != None)
    {
        ExploActor.InstigatorController = Player.Controller;
        ExploActor.Instigator = Player;
        ExploActor.Explode(ForgeExplosionTemplate, vect(0, 0, 1));

        `log("ZR GildedTouch: Forge Detonation! Dmg=" $ int(ScaledDamage) @ "Rad=" $ int(ScaledRadius));
    }

    // Play detonation sound
    PlayDetonationSound('Artificer_Gilded_Touch');
}

// ===================================================================
// SOUND — Uses DKSoundManager pattern
// ===================================================================

function PlayDetonationSound(name SoundID)
{
    local DKPlayerController DKPC;
    local DKMutator Mut;
    local SoundCue Sound;

    if (Player == None || Player.Controller == None)
        return;

    DKPC = DKPlayerController(Player.Controller);
    if (DKPC == None)
        return;

    Mut = class'DKSoundManager'.static.GetMutator(WorldInfo);
    if (Mut == None)
        return;

    Sound = class'DKSoundManager'.static.GetSound(Mut, SoundID);
    if (Sound != None)
        DKPC.ClientPlayBuffSound(Sound);
}

defaultproperties
{
    RemoteRole=ROLE_None
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
    bHidden=True
    bCollideActors=False
    bBlockActors=False

    UpgradeLevel=1
    LastDetonationTime=0.0f
    DetonationCooldown=0.15f    // 150ms between detonations to prevent spam

    // Forge Detonation explosion template
    // Damage and DamageRadius are overwritten per-call with scaled values
    Begin Object Class=KFGameExplosion Name=ForgeExploTemplate
        Damage=30.0f
        DamageRadius=150.0f
        DamageFalloffExponent=2.0f
        DamageDelay=0.0f
        bFullDamageToAttachee=False

        // Explosion does NOT hurt the player
        bIgnoreInstigator=True
        ActorClassToIgnoreForDamage=class'KFGame.KFPawn_Human'

        // Damage type — standard explosive
        MyDamageType=class'KFDT_Explosive'

        // Visual effects — fiery forge explosion (uses existing Husk suicide FX)
        ExplosionEffects=KFImpactEffectInfo'FX_Impacts_ARCH.Explosions.HuskSuicide_Explosion'
        ExplosionSound=AkEvent'WW_WEP_Husk_Cannon.Play_WEP_Husk_Cannon_3P_Fire'

        // Physics
        KnockDownStrength=0.0f
        MomentumTransferScale=5000.0f
        FractureMeshRadius=200.0f
        FracturePartVel=500.0f

        // Camera shake (subtle, scales with radius)
        CamShake=CameraShake'FX_CameraShake_Arch.Misc_Explosions.Seeker6'
        CamShakeInnerRadius=150.0f
        CamShakeOuterRadius=400.0f
        CamShakeFalloff=1.5f
        bOrientCameraShakeTowardsEpicenter=True
    End Object
    ForgeExplosionTemplate=ForgeExploTemplate

    Name="Default__DKUpgrade_Skill_GildedTouch_Helper"
}
