class ZTUpgrade_Skill_GorgonsLegacy_Helper extends Info transient;

var KFPawn_Human Player;
var int UpgradeLevel;
var bool bLegacyBuffActive;
var float BuffTimeRemaining;
var bool bInvincibilityActive;
var float InvincibilityTimeRemaining;
var const float InvincibilityDuration;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None)
        Destroy();
    else
    {
        bLegacyBuffActive = false;
        BuffTimeRemaining = 0.0f;
        bInvincibilityActive = false;
        InvincibilityTimeRemaining = 0.0f;
        SetTimer(1.0f, True);
        
        // Register death detection
        RegisterDeathCallback();
    }
}

function Timer()
{
    if (Player == None)
    {
        Destroy();
        return;
    }

    // Update legacy buff timer
    if (bLegacyBuffActive && BuffTimeRemaining > 0.0f)
    {
        BuffTimeRemaining -= 1.0f;
        
        if (BuffTimeRemaining <= 0.0f)
        {
            DeactivateLegacyBuff();
        }
    }
    
    // Update invincibility timer
    if (bInvincibilityActive && InvincibilityTimeRemaining > 0.0f)
    {
        InvincibilityTimeRemaining -= 1.0f;
        
        if (InvincibilityTimeRemaining <= 0.0f)
        {
            DeactivateInvincibility();
        }
    }
}

function RegisterDeathCallback()
{
    // This would ideally hook into the player's death event
    // For now, we'll check health in timer or use other mechanisms
}

function ActivateLegacyBuff(int SkillLevel)
{
    local KFPlayerController KFPC;
    local float Duration;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC == None) return;
    
    // Get buff duration based on skill level
    if (SkillLevel == 1)
        Duration = 45.0f;
    else
        Duration = 60.0f;
    
    bLegacyBuffActive = true;
    BuffTimeRemaining = Duration;
    
    // For Deluxe version, also activate brief invincibility
    if (SkillLevel == 2)
    {
        ActivateInvincibility();
    }
    
    // Critical - major team buff from player death
    class'ZTMessageManager'.static.SendCritical(KFPC, "Gorgon's Legacy: Inherited power! +" $ (SkillLevel == 1 ? 25 : 50) $ "% damage for " $ int(Duration) $ " seconds!");
}

function ActivateInvincibility()
{
    local KFPlayerController KFPC;
    
    bInvincibilityActive = true;
    InvincibilityTimeRemaining = InvincibilityDuration;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Critical - invincibility activation
        class'ZTMessageManager'.static.SendCritical(KFPC, "Gorgon's Legacy: Brief invincibility granted!");
    }
}

function DeactivateLegacyBuff()
{
    local KFPlayerController KFPC;
    
    bLegacyBuffActive = false;
    BuffTimeRemaining = 0.0f;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Minor - buff expiration
        class'ZTMessageManager'.static.SendMinor(KFPC, "Gorgon's Legacy: Power fades...");
    }
}

function DeactivateInvincibility()
{
    local KFPlayerController KFPC;
    
    bInvincibilityActive = false;
    InvincibilityTimeRemaining = 0.0f;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Minor - buff expiration
        class'ZTMessageManager'.static.SendMinor(KFPC, "Gorgon's Legacy: Invincibility ended");
    }
}

// Override damage taken to implement invincibility
function bool ShouldTakeDamage()
{
    return !bInvincibilityActive;
}

// Function called when the player with this skill dies
function TriggerLegacyOnDeath()
{
    // Trigger the legacy buff for all teammates
    class'ZTUpgrade_Skill_GorgonsLegacy'.static.TriggerGorgonsLegacy(Player, UpgradeLevel);
}

defaultproperties
{
    UpgradeLevel=1
    bLegacyBuffActive=false
    BuffTimeRemaining=0.0f
    bInvincibilityActive=false
    InvincibilityTimeRemaining=0.0f
    InvincibilityDuration=3.0f      // 3 seconds of invincibility
    
    Name="Default__ZTUpgrade_Skill_GorgonsLegacy_Helper"
}