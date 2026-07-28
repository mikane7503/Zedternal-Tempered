class DKUpgrade_Skill_HuntDown_Helper extends Info;

var KFPawn_Monster LastTarget;
var int CurrentStacks;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Owner == None)
        Destroy();
    
    LastTarget = None;
    CurrentStacks = 0;
}

function int RegisterHit(KFPawn_Monster Target, int MaxStacks)
{
    local int StacksToApply;
    local KFPlayerController KFPC;
    
    if (Target == None)
    {
        // No valid target, reset
        LastTarget = None;
        CurrentStacks = 0;
        return 0;
    }
    
    // Check if same target as last hit
    if (Target == LastTarget)
    {
        // Same target - return current stacks, then increment
        StacksToApply = CurrentStacks;
        
        if (CurrentStacks < MaxStacks)
        {
            CurrentStacks++;
            
            // Notify on stack gain
            if (CurrentStacks > 1)
            {
                KFPC = KFPlayerController(Pawn(Owner).Controller);
                if (KFPC != None)
                {
                    KFPC.ClientMessage("Hunt Down: " $ CurrentStacks $ "x", 'Event');
                }
            }
        }
    }
    else
    {
        // Different target - reset stacks
        StacksToApply = 0;
        LastTarget = Target;
        CurrentStacks = 1;
    }
    
    return StacksToApply;
}

function ResetStacks()
{
    LastTarget = None;
    CurrentStacks = 0;
}

defaultproperties
{
    CurrentStacks=0
    
    Name="Default__DKUpgrade_Skill_HuntDown_Helper"
}
