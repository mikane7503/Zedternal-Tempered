class DKUpgrade_Skill_Reaper_Helper extends Info
    transient
    hidecategories(Navigation,Movement,Collision);

var KFPawn_Human Player;
var int UpgradeLevel;
var int TotalHealthGained;
var int LastAppliedHealthMax;

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
    local int HealthCap;

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
            // Health was reset, reapply our bonus - but never past the
            // configured PlayerCaps max health. Without this clamp the
            // reapply loop pushed the bonus back on top every time the
            // perk pipeline clamped HealthMax, permanently defeating
            // Cap_MaxHealth.
            Player.HealthMax += TotalHealthGained;

            HealthCap = GetHealthCap();
            if (HealthCap > 0 && Player.HealthMax > HealthCap)
                Player.HealthMax = HealthCap;
            if (Player.Health > Player.HealthMax)
                Player.Health = Player.HealthMax;

            LastAppliedHealthMax = Player.HealthMax;
        }
        else if(Player.HealthMax != LastAppliedHealthMax)
        {
            // Health was changed by something else, update our tracking
            LastAppliedHealthMax = Player.HealthMax;
        }
    }
}

// Returns the configured max health cap, or 0 when caps are disabled.
function int GetHealthCap()
{
    if (!class'DKConfig_PlayerCaps'.static.IsEnabled())
        return 0;
    return class'DKConfig_PlayerCaps'.static.GetCapMaxHealth();
}

function AddPermanentHealth()
{
    local int HealthToAdd;
    local int HealthCap;
    
    // BUGFIX: the health-per-kill amounts previously came from a hardcoded
    // array in this helper, so the HealthGain values in the INI section
    // [ZedternalRBPerkpackage.DKUpgrade_Skill_Reaper] were ignored. Read
    // the skill class config directly instead.
    if(UpgradeLevel > 0 && UpgradeLevel <= class'DKUpgrade_Skill_Reaper'.default.HealthGain.Length)
    {
        HealthToAdd = class'DKUpgrade_Skill_Reaper'.default.HealthGain[UpgradeLevel - 1];

        // PLAYERCAPS: this is a direct HealthMax write that bypasses the
        // DKPerk.ModifyHealth clamp, so the cap must be enforced here too.
        // Only the portion that fits under Cap_MaxHealth is granted and
        // credited to TotalHealthGained, otherwise the reapply loop would
        // push the excess back after every perk recompute.
        HealthCap = GetHealthCap();
        if (HealthCap > 0)
            HealthToAdd = Min(HealthToAdd, HealthCap - Player.HealthMax);

        if (HealthToAdd <= 0)
            return;

        TotalHealthGained += HealthToAdd;
        
        // Apply immediately
        Player.HealthMax += HealthToAdd;
        Player.Health += HealthToAdd;
        LastAppliedHealthMax = Player.HealthMax;
    }
}

defaultproperties
{
    begin object name="Sprite"
        ReplacementPrimitive=none
    end object
    Components(0)=Sprite
}