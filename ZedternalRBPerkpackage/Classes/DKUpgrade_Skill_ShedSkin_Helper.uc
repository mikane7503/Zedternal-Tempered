class DKUpgrade_Skill_ShedSkin_Helper extends Info
    transient;

var KFPawn_Human Player;
var int UpgradeLevel;
var bool bBuffActive;
var float BuffTimeRemaining;
var float CooldownTimeRemaining;
var int DamageInWindow;
var float DamageWindowTimer;
var const float DamageWindowDuration;

struct DamageEvent
{
    var float TimeStamp;
    var int DamageAmount;
};

var array<DamageEvent> RecentDamage;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        bBuffActive = false;
        BuffTimeRemaining = 0.0f;
        CooldownTimeRemaining = 0.0f;
        DamageInWindow = 0;
        DamageWindowTimer = 0.0f;
        SetTimer(1.0f, True);
    }
}

function Timer()
{
    local float CurrentTime;
    
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    
    // Update buff timer
    if (bBuffActive && BuffTimeRemaining > 0.0f)
    {
        BuffTimeRemaining -= 1.0f;
        
        if (BuffTimeRemaining <= 0.0f)
        {
            bBuffActive = false;
            ShowBuffEnd();
        }
    }
    
    // Update cooldown timer
    if (CooldownTimeRemaining > 0.0f)
    {
        CooldownTimeRemaining -= 1.0f;
    }
    
    // Clean up old damage events (older than 3 seconds)
    CleanupOldDamage(CurrentTime);
}

function TrackDamage(int DamageAmount, int SkillLevel)
{
    local float CurrentTime;
    local DamageEvent NewEvent;
    local int TotalDamageInWindow;
    local int DamageTrigger;
    local float BuffDuration, CooldownDuration;
    local KFPlayerController KFPC;
    
    if (bBuffActive || CooldownTimeRemaining > 0.0f) return;
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    
    // Add new damage event
    NewEvent.TimeStamp = CurrentTime;
    NewEvent.DamageAmount = DamageAmount;
    RecentDamage.AddItem(NewEvent);
    
    // Calculate total damage in the last 3 seconds
    TotalDamageInWindow = CalculateDamageInWindow(CurrentTime);
    
    // Get trigger threshold and buff parameters. Trigger and duration are
    // config-driven ([ZedternalRBPerkpackage.DKUpgrade_Skill_ShedSkin]
    // DamageTrigger / BuffDuration, index 0 = standard, 1 = deluxe).
    if (SkillLevel == 1)
    {
        DamageTrigger = class'DKUpgrade_Skill_ShedSkin'.default.DamageTrigger[0];
        BuffDuration = class'DKUpgrade_Skill_ShedSkin'.default.BuffDuration[0];
        CooldownDuration = 30.0f;
    }
    else
    {
        DamageTrigger = class'DKUpgrade_Skill_ShedSkin'.default.DamageTrigger[1];
        BuffDuration = class'DKUpgrade_Skill_ShedSkin'.default.BuffDuration[1];
        CooldownDuration = 20.0f;
    }
    
    // Check if trigger condition is met
    if (TotalDamageInWindow >= DamageTrigger)
    {
        // Activate buff (Important - major defensive buff activation)
        bBuffActive = true;
        BuffTimeRemaining = BuffDuration;
        CooldownTimeRemaining = CooldownDuration;
        
        KFPC = KFPlayerController(Player.Controller);
        if (KFPC != None)
        {
            class'DKMessageManager'.static.SendImportant(KFPC, "Shed Skin: Damage resistance activated! " $ int(BuffDuration) $ "s protection");
        }
        
        // Clear damage window
        RecentDamage.Length = 0;
    }
}

function int CalculateDamageInWindow(float CurrentTime)
{
    local int i, TotalDamage;
    
    TotalDamage = 0;
    
    for (i = 0; i < RecentDamage.Length; i++)
    {
        if (CurrentTime - RecentDamage[i].TimeStamp <= DamageWindowDuration)
        {
            TotalDamage += RecentDamage[i].DamageAmount;
        }
    }
    
    return TotalDamage;
}

function CleanupOldDamage(float CurrentTime)
{
    local int i;
    local array<DamageEvent> NewRecentDamage;
    
    // Keep only damage events from the last 3 seconds
    for (i = 0; i < RecentDamage.Length; i++)
    {
        if (CurrentTime - RecentDamage[i].TimeStamp <= DamageWindowDuration)
        {
            NewRecentDamage.AddItem(RecentDamage[i]);
        }
    }
    
    RecentDamage = NewRecentDamage;
}

function ShowBuffEnd()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Minor - buff expiration
        class'DKMessageManager'.static.SendMinor(KFPC, "Shed Skin: Protection ended");
    }
}

defaultproperties
{
    UpgradeLevel=1
    bBuffActive=false
    BuffTimeRemaining=0.0f
    CooldownTimeRemaining=0.0f
    DamageInWindow=0
    DamageWindowTimer=0.0f
    DamageWindowDuration=3.0f       // 3 second damage window
    
    Name="Default__DKUpgrade_Skill_ShedSkin_Helper"
}