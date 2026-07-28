class DKUpgrade_Skill_CascadingMassacre_Helper extends Info;

var int CurrentStacks;
var int MaxStacks;
var float StackDuration;
var float LastKillTime;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Owner == None)
        Destroy();
    
    CurrentStacks = 0;
    LastKillTime = 0.0f;
}

function int GetCurrentStacks()
{
    local float CurrentTime;
    
    if (Owner == None)
        return 0;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Check if stacks have expired
    if (CurrentStacks > 0 && (CurrentTime - LastKillTime) > StackDuration)
    {
        CurrentStacks = 0;
    }
    
    return CurrentStacks;
}

function RegisterKill()
{
    local float CurrentTime;
    local KFPlayerController KFPC;
    
    if (Owner == None)
        return;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    // Check if we're within the chain window
    if (CurrentStacks > 0 && (CurrentTime - LastKillTime) > StackDuration)
    {
        // Chain broken, reset
        CurrentStacks = 0;
    }
    
    // Add a stack (up to max)
    if (CurrentStacks < MaxStacks)
    {
        CurrentStacks++;
    }
    
    LastKillTime = CurrentTime;
    
    // Set timer to reset stacks after duration expires
    SetTimer(StackDuration + 0.1f, false, 'CheckStackExpiry');
    
    // Notify player of stack count
    if (CurrentStacks > 1)
    {
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("Cascading Massacre: " $ CurrentStacks $ "x", 'Event');
        }
    }
}

function CheckStackExpiry()
{
    local float CurrentTime;
    
    if (Owner == None)
        return;
    
    CurrentTime = Owner.WorldInfo.TimeSeconds;
    
    if ((CurrentTime - LastKillTime) >= StackDuration)
    {
        CurrentStacks = 0;
    }
}

defaultproperties
{
    CurrentStacks=0
    MaxStacks=5
    StackDuration=2.0f
    LastKillTime=0.0f
    
    Name="Default__DKUpgrade_Skill_CascadingMassacre_Helper"
}
