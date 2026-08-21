class ZTUpgrade_Skill_VenomExtraction_Helper extends Info transient;

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
    
    // Determine max stacks based on skill level
    if (SkillLevel == 1)
    {
        MaxStacks = 1;
        DamagePerStack = 10.0f;
    }
    else
    {
        MaxStacks = 5;
        DamagePerStack = 20.0f;
    }
    
    // Add stack (capped at max)
    CurrentStacks = Min(CurrentStacks + 1, MaxStacks);
    BuffDuration = MaxBuffDuration;
    
    // Show notification (Important - buff activation/stack gain)
    class'ZTMessageManager'.static.SendImportant(KFPC, "Venom Extraction: +" $ int(DamagePerStack) $ "% damage (" $ CurrentStacks $ "/" $ MaxStacks $ " stacks) for " $ int(BuffDuration) $ "s");
}

function ShowBuffEnd()
{
    local KFPlayerController KFPC;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Minor - buff expiration
        class'ZTMessageManager'.static.SendMinor(KFPC, "Venom Extraction: Damage buff expired");
    }
}

defaultproperties
{
    UpgradeLevel=1
    CurrentStacks=0
    BuffDuration=0.0f
    MaxBuffDuration=10.0f           // 10 seconds duration
    
    Name="Default__ZTUpgrade_Skill_VenomExtraction_Helper"
}