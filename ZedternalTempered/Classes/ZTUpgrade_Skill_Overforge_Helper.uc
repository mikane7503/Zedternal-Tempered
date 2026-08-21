// ===================================================================
// ZTUpgrade_Skill_Overforge_Helper — Hit Stack Tracker
//
// Tracks consecutive hits to build Forge Heat stacks.
// At 10 stacks, the next hit becomes an Overforged Strike.
// Switching weapons resets stacks to 0.
// Spawned as child actor of KFPawn_Human (server-side).
//
// Sound: Plays 'Artificer_Overforge_Strike' on burst via ZTSoundManager.
// ===================================================================
class ZTUpgrade_Skill_Overforge_Helper extends Info;

var int UpgradeLevel;
var KFPawn_Human Player;

// Stack tracking
var int HitStacks;
var string TrackedWeaponName;     // Normalized name of weapon building stacks

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

    HitStacks = 0;
    TrackedWeaponName = "";
}

// ===================================================================
// ON HIT — Called from ZTUpgrade_Skill_Overforge.ModifyDamageGiven
// Modifies InDamage directly when Overforged Strike triggers.
// ===================================================================

function OnHit(KFWeapon KFW, out int InDamage, int DefaultDamage, int upgLevel)
{
    local string NormName;
    local int Threshold;
    local float BurstBonus;

    if (KFW == None || Player == None)
        return;

    NormName = class'ZTUpgrade_Perk_Artificer'.static.NormalizeWeaponName(string(KFW.Class.Name));
    Threshold = class'ZTUpgrade_Skill_Overforge'.default.StackThreshold;

    // Weapon switch detection — reset stacks
    if (NormName != TrackedWeaponName)
    {
        TrackedWeaponName = NormName;
        HitStacks = 0;
    }

    // Increment stacks
    HitStacks += 1;

    // Check if we've reached the threshold
    if (HitStacks >= Threshold)
    {
        // OVERFORGED STRIKE — apply burst damage
        BurstBonus = class'ZTUpgrade_Skill_Overforge'.default.BurstDamage[upgLevel - 1];
        InDamage += Round(float(DefaultDamage) * BurstBonus);

        // Reset stacks
        HitStacks = 0;

        // Play strike sound
        PlayOverforgeSound('Artificer_Overforge_Strike');

        `log("ZR Overforge: OVERFORGED STRIKE! +" $ int(BurstBonus * 100) $ "% damage on" @ NormName);
    }
}

// ===================================================================
// SOUND — Uses ZTSoundManager pattern
// ===================================================================

function PlayOverforgeSound(name SoundID)
{
    local ZTPlayerController DKPC;
    local ZTMutator Mut;
    local SoundCue Sound;

    if (Player == None || Player.Controller == None)
        return;

    DKPC = ZTPlayerController(Player.Controller);
    if (DKPC == None)
        return;

    Mut = class'ZTSoundManager'.static.GetMutator(WorldInfo);
    if (Mut == None)
        return;

    Sound = class'ZTSoundManager'.static.GetSound(Mut, SoundID);
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
    HitStacks=0
    TrackedWeaponName=""

    Name="Default__ZTUpgrade_Skill_Overforge_Helper"
}
