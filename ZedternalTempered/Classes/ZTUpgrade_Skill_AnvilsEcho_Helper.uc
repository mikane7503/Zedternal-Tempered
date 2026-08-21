// ===================================================================
// ZTUpgrade_Skill_AnvilsEcho_Helper — Hit Counter for Phantom Echo
//
// Tracks total hits across all weapons. Every Nth hit triggers
// a phantom echo dealing +50% bonus damage. Counter persists
// across weapon switches — no reset, purely additive.
// Spawned as child actor of KFPawn_Human (server-side).
//
// Sound: Plays 'Artificer_Anvils_Echo' on proc via ZTSoundManager.
// ===================================================================
class ZTUpgrade_Skill_AnvilsEcho_Helper extends Info;

var int UpgradeLevel;
var KFPawn_Human Player;

// Hit tracking
var int TotalHits;

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

    TotalHits = 0;
}

// ===================================================================
// ON HIT — Called from ZTUpgrade_Skill_AnvilsEcho.ModifyDamageGiven
// Modifies InDamage directly when echo triggers.
// ===================================================================

function OnHit(out int InDamage, int DefaultDamage, int upgLevel)
{
    local int Interval;
    local float EchoBonus;

    if (Player == None)
        return;

    // Increment hit counter
    TotalHits += 1;

    // Check interval based on upgrade level
    Interval = class'ZTUpgrade_Skill_AnvilsEcho'.default.HitInterval[upgLevel - 1];
    if (Interval <= 0)
        return;

    // Check if this is the Nth hit
    if ((TotalHits % Interval) == 0)
    {
        // PHANTOM ECHO — apply bonus damage
        EchoBonus = class'ZTUpgrade_Skill_AnvilsEcho'.default.EchoDamage;
        InDamage += Round(float(DefaultDamage) * EchoBonus);

        // Play echo sound
        PlayEchoSound('Artificer_Anvils_Echo');
    }
}

// ===================================================================
// SOUND — Uses ZTSoundManager pattern
// ===================================================================

function PlayEchoSound(name SoundID)
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
    TotalHits=0

    Name="Default__ZTUpgrade_Skill_AnvilsEcho_Helper"
}
