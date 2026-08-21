class DKUpgrade_Skill_VenomExtraction_Helper extends Info
    transient;

var KFPawn_Human Player;
var int UpgradeLevel;
var int CurrentStacks;
var float BuffDuration;
var const float MaxBuffDuration;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        CurrentStacks = 0;
        BuffDuration = 0.0f;
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

    // Update buff timer
    if (CurrentStacks > 0 && BuffDuration > 0.0f)
    {
        BuffDuration -= 1.0f;
        
        if (BuffDuration <= 0.0f)
        {
            CurrentStacks = 0;
            ShowBuffEnd();
        }
    }
}

function AddVenomStack(int SkillLevel)
{
    local KFPlayerController KFPC;
    local int MaxStacks;
    local float DamagePerStack;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC == None) return;
    
    // Determine max stacks based on skill level. Config-driven:
    // [ZedternalRBPerkpackage.DKUpgrade_Skill_VenomExtraction] MaxStacks /
    // DamageBonus (index 0 = standard, 1 = deluxe). DamagePerStack is the
    // display percentage of the config bonus so the popup never lies.
    if (SkillLevel == 1)
    {
        MaxStacks = class'DKUpgrade_Skill_VenomExtraction'.default.MaxStacks[0];
        DamagePerStack = class'DKUpgrade_Skill_VenomExtraction'.default.DamageBonus[0] * 100.0f;
    }
    else
    {
        MaxStacks = class'DKUpgrade_Skill_VenomExtraction'.default.MaxStacks[1];
        DamagePerStack = class'DKUpgrade_Skill_VenomExtraction'.default.DamageBonus[1] * 100.0f;
    }
    
    // Add stack (capped at max)
    CurrentStacks = Min(CurrentStacks + 1, MaxStacks);
    BuffDuration = MaxBuffDuration;
    
    // Show notification (Important - buff activation/stack gain)
    class'DKMessageManager'.static.SendImportant(KFPC, "Venom Extraction: +" $ int(DamagePerStack) $ "% damage (" $ CurrentStacks $ "/" $ MaxStacks $ " stacks) for " $ int(BuffDuration) $ "s");
}

function ShowBuffEnd()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Minor - buff expiration
        class'DKMessageManager'.static.SendMinor(KFPC, "Venom Extraction: Damage buff expired");
    }
}

defaultproperties
{
    UpgradeLevel=1
    CurrentStacks=0
    BuffDuration=0.0f
    MaxBuffDuration=10.0f           // 10 seconds duration
    
    Name="Default__DKUpgrade_Skill_VenomExtraction_Helper"
}