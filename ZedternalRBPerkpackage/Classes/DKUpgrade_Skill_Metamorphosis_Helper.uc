class DKUpgrade_Skill_Metamorphosis_Helper extends Info
    transient;

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
    
    RequiredKills = 50; // Both versions require 50 poison kills
    
    // Check if we've reached the required kills
    if (PoisonKillsThisWave >= RequiredKills)
    {
        TriggerTransformation(SkillLevel);
    }
    else
    {
        // Show progress (Minor - progress tracking)
        class'DKMessageManager'.static.SendMinor(KFPC, "Metamorphosis: " $ PoisonKillsThisWave $ "/" $ RequiredKills $ " poison kills");
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
    
    // Get transformation parameters based on skill level
    if (SkillLevel == 1)
    {
        Duration = 5.0f;
        StatBonus = 10;
    }
    else
    {
        Duration = 10.0f;
        StatBonus = 20;
    }
    
    // Activate transformation
    bTransformationActive = true;
    TransformTimeRemaining = Duration;
    bTransformationUsedThisWave = true;
    
    // Show dramatic transformation message (Critical - ultimate transformation)
    class'DKMessageManager'.static.SendCritical(KFPC, "*** METAMORPHOSIS ACTIVATED! ***");
    class'DKMessageManager'.static.SendCritical(KFPC, "Gorgon transformation: +" $ StatBonus $ "% all stats, immune to damage for " $ int(Duration) $ " seconds!");
    
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
        class'DKMessageManager'.static.SendImportant(KFPC, "Metamorphosis: Transformation ended, returning to normal form");
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
        class'DKMessageManager'.static.SendMinor(KFPC, "Metamorphosis: Progress reset for new wave");
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
    
    RequiredKills = 50;
    
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
    
    Name="Default__DKUpgrade_Skill_Metamorphosis_Helper"
}