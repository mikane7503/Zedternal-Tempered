class DKUpgrade_Skill_FrostbiteArrows_Helper extends Info
    transient;

struct FrostbiteStack
{
    var KFPawn_Monster Target;
    var int StackCount;
    var float LastStackTime;
};

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var array<FrostbiteStack> FrostbiteStacks;
var const float Update, StackDuration, DeduplicationWindow;
var const int MaxStacks;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
        SetTimer(Update, True);
}

function Timer()
{
    local int i;
    local float CurrentTime;

    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    CurrentTime = Player.WorldInfo.TimeSeconds;

    // Clean up expired stacks and dead targets
    for (i = FrostbiteStacks.Length - 1; i >= 0; i--)
    {
        if (FrostbiteStacks[i].Target == None || 
            !FrostbiteStacks[i].Target.IsAliveAndWell() ||
            (CurrentTime - FrostbiteStacks[i].LastStackTime) > StackDuration)
        {
            FrostbiteStacks.Remove(i, 1);
        }
    }
}

function ApplyFrostbiteStack(KFPawn_Monster Target)
{
    local int i;
    local float CurrentTime;
    local FrostbiteStack NewStack;

    if (Target == None || !Target.IsAliveAndWell())
        return;

    CurrentTime = Player.WorldInfo.TimeSeconds;

    // Check deduplication window to prevent multiple stacks from rapid fire
    for (i = 0; i < FrostbiteStacks.Length; i++)
    {
        if (FrostbiteStacks[i].Target == Target)
        {
            if ((CurrentTime - FrostbiteStacks[i].LastStackTime) < DeduplicationWindow)
                return; // Too soon, ignore this stack

            // Add stack to existing target
            FrostbiteStacks[i].StackCount = Min(FrostbiteStacks[i].StackCount + 1, MaxStacks);
            FrostbiteStacks[i].LastStackTime = CurrentTime;
            return;
        }
    }

    // New target, create first stack
    NewStack.Target = Target;
    NewStack.StackCount = 1;
    NewStack.LastStackTime = CurrentTime;
    FrostbiteStacks.AddItem(NewStack);
}

function float GetDamageBonusForTarget(KFPawn_Monster Target)
{
    local int i;

    if (Target == None)
        return 0.0f;

    for (i = 0; i < FrostbiteStacks.Length; i++)
    {
        if (FrostbiteStacks[i].Target == Target)
        {
            return float(FrostbiteStacks[i].StackCount) * class'DKUpgrade_Skill_FrostbiteArrows'.default.DamagePerStack[UpgradeLevel - 1];
        }
    }

    return 0.0f;
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    Update=1.0f
    StackDuration=10.0f
    DeduplicationWindow=0.2f
    MaxStacks=5

    Name="Default__DKUpgrade_Skill_FrostbiteArrows_Helper"
}