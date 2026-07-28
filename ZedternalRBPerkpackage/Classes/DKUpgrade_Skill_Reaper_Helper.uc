class DKUpgrade_Skill_Reaper_Helper extends Info
    transient
    hidecategories(Navigation,Movement,Collision);

var KFPawn_Human Player;
var int UpgradeLevel;
var int TotalHealthGained;
var int LastAppliedHealthMax;
var array<int> HealthPerKill;

function PostBeginPlay()
{
    Super.PostBeginPlay();
    Player = KFPawn_Human(Owner);
    
    if(Player == none || Player.Health <= 0)
    {
        Destroy();
        return;
    }
    
    TotalHealthGained = 0;
    LastAppliedHealthMax = Player.HealthMax;
    SetTimer(0.1, true, 'ApplyHealthBonus');
}

function ApplyHealthBonus()
{
    if(Player == none || Player.Health <= 0)
    {
        Destroy();
        return;
    }
    
    // If the player's HealthMax has changed (from other sources), we need to reapply our bonus
    if(TotalHealthGained > 0)
    {
        // Check if our bonus needs to be reapplied
        if(Player.HealthMax < LastAppliedHealthMax)
        {
            // Health was reset, reapply our bonus
            Player.HealthMax += TotalHealthGained;
            LastAppliedHealthMax = Player.HealthMax;
        }
        else if(Player.HealthMax != LastAppliedHealthMax)
        {
            // Health was changed by something else, update our tracking
            LastAppliedHealthMax = Player.HealthMax;
        }
    }
}

function AddPermanentHealth()
{
    local int HealthToAdd;
    
    if(UpgradeLevel > 0 && UpgradeLevel <= HealthPerKill.Length)
    {
        HealthToAdd = HealthPerKill[UpgradeLevel - 1];
        TotalHealthGained += HealthToAdd;
        
        // Apply immediately
        Player.HealthMax += HealthToAdd;
        Player.Health += HealthToAdd;
        LastAppliedHealthMax = Player.HealthMax;
    }
}

defaultproperties
{
    HealthPerKill(0)=1
    HealthPerKill(1)=2
    
    begin object name="Sprite"
        ReplacementPrimitive=none
    end object
    Components(0)=Sprite
}