class ZTUpgrade_Skill_Metamorphosis_Helper extends Info transient;

var KFPawn_Human Player;
var int UpgradeLevel;
var int PoisonKillsThisWave;
var bool bTransformationActive;
var float TransformTimeRemaining;
var bool bTransformationUsedThisWave;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        PoisonKillsThisWave = 0;
        bTransformationActive = false;
        TransformTimeRemaining = 0.0f;
        bTransformationUsedThisWave = false;
        SetTimer(1.0f, True);
    }
}

function Timer()
{
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    // Update transformation timer
    if (bTransformationActive && TransformTimeRemaining > 0.0f)
    {
        TransformTimeRemaining -= 1.0f;
        
        if (TransformTimeRemaining <= 0.0f)
        {
            DeactivateTransformation();
        }
    }
}

function TrackPoisonKill(int SkillLevel)
{
    local KFPlayerController KFPC;
    local int RequiredKills;
    
    // Only count if transformation hasn't been used this wave
    if (bTransformationUsedThisWave) return;
    
    PoisonKillsThisWave++;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC == None) return;
    
    // Kill requirement is config-driven:
    // [ZedternalTempered.ZTUpgrade_Skill_Metamorphosis] PoisonKillsRequired
    // (index 0 = standard, 1 = deluxe)
    if (SkillLevel == 1)
        RequiredKills = class'ZTUpgrade_Skill_Metamorphosis'.default.PoisonKillsRequired[0];
    else
        RequiredKills = class'ZTUpgrade_Skill_Metamorphosis'.default.PoisonKillsRequired[1];
    
    // Check if we've reached the required kills
    if (PoisonKillsThisWave >= RequiredKills)
    {
        TriggerTransformation(SkillLevel);
    }
    else
    {
        // Show progress (Minor - progress tracking)
        class'ZTMessageManager'.static.SendMinor(KFPC, "Metamorphosis: " $ PoisonKillsThisWave $ "/" $ RequiredKills $ " poison kills");
    }
}

function TriggerTransformation(int SkillLevel)
{
    local KFPlayerController KFPC;
    local float Duration;
    local int StatBonus;
    
    if (bTransformationActive || bTransformationUsedThisWave) return;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC == None) return;
    
    // Get transformation parameters based on skill level. Duration is
    // config-driven (TransformDuration, index 0 = standard, 1 = deluxe).
    if (SkillLevel == 1)
    {
        Duration = class'ZTUpgrade_Skill_Metamorphosis'.default.TransformDuration[0];
        StatBonus = 10;
    }
    else
    {
        Duration = class'ZTUpgrade_Skill_Metamorphosis'.default.TransformDuration[1];
        StatBonus = 20;
    }
    
    // Activate transformation
    bTransformationActive = true;
    TransformTimeRemaining = Duration;
    bTransformationUsedThisWave = true;
    
    // Show dramatic transformation message (Critical - ultimate transformation)
    class'ZTMessageManager'.static.SendCritical(KFPC, "*** METAMORPHOSIS ACTIVATED! ***");
    class'ZTMessageManager'.static.SendCritical(KFPC, "Gorgon transformation: +" $ StatBonus $ "% all stats, immune to damage for " $ int(Duration) $ " seconds!");
    
    // Visual/audio feedback could be added here
    PlayTransformationEffects();
}

function DeactivateTransformation()
{
    local KFPlayerController KFPC;
    
    bTransformationActive = false;
    TransformTimeRemaining = 0.0f;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Important - transformation ending
        class'ZTMessageManager'.static.SendImportant(KFPC, "Metamorphosis: Transformation ended, returning to normal form");
    }
}

function ResetWaveProgress()
{
    local KFPlayerController KFPC;
    
    // Reset for new wave
    PoisonKillsThisWave = 0;
    bTransformationUsedThisWave = false;
    
    // End any active transformation
    if (bTransformationActive)
    {
        DeactivateTransformation();
    }
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Minor - wave reset notification
        class'ZTMessageManager'.static.SendMinor(KFPC, "Metamorphosis: Progress reset for new wave");
    }
}

function PlayTransformationEffects()
{
    local KFPlayerController KFPC;
    
    // Play transformation sound/visual effects
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Could add special effects here
        // KFPC.PlayRMEffect(TransformationSound, SoundRTPCName, UpgradeLevel);
    }
}

function string GetProgressStatus()
{
    local string Status;
    local int RequiredKills;
    
    // Display-only; no skill level in scope, use the standard index (both
    // seeds are 50 by default, config-driven).
    RequiredKills = class'ZTUpgrade_Skill_Metamorphosis'.default.PoisonKillsRequired[0];
    
    if (bTransformationActive)
    {
        Status = "TRANSFORMED! " $ int(TransformTimeRemaining) $ "s remaining";
    }
    else if (bTransformationUsedThisWave)
    {
        Status = "Transformation used this wave";
    }
    else
    {
        Status = "Progress: " $ PoisonKillsThisWave $ "/" $ RequiredKills $ " poison kills";
    }
    
    return Status;
}

defaultproperties
{
    UpgradeLevel=1
    PoisonKillsThisWave=0
    bTransformationActive=false
    TransformTimeRemaining=0.0f
    bTransformationUsedThisWave=false
    
    Name="Default__ZTUpgrade_Skill_Metamorphosis_Helper"
}