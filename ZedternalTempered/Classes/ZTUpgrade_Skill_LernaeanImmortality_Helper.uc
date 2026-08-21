class ZTUpgrade_Skill_LernaeanImmortality_Helper extends Info;

var bool bChargeAvailable;
var bool bInvulnerable;
var bool bDamageBoost;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Owner == None)
        Destroy();
    
    bChargeAvailable = true;
    bInvulnerable = false;
    bDamageBoost = false;
}

function TriggerImmortality(float Duration)
{
    local KFPlayerController KFPC;
    
    // Consume the charge
    bChargeAvailable = false;
    
    // Activate buffs
    bInvulnerable = true;
    bDamageBoost = true;
    
    // Set timer to end effects
    SetTimer(Duration, false, 'EndImmortality');
    
    // Notify player
    if (Owner != None)
    {
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("LERNAEAN IMMORTALITY TRIGGERED! " $ int(Duration) $ " seconds of invulnerability + double damage!", 'Event');
        }
    }
}

function EndImmortality()
{
    local KFPlayerController KFPC;
    
    bInvulnerable = false;
    bDamageBoost = false;
    
    // Notify player
    if (Owner != None)
    {
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("Lernaean Immortality has ended.", 'Event');
        }
    }
}

function ResetCharge()
{
    local KFPlayerController KFPC;
    local bool bWasUsed;
    
    bWasUsed = !bChargeAvailable;
    
    bChargeAvailable = true;
    bInvulnerable = false;
    bDamageBoost = false;
    ClearTimer('EndImmortality');
    
    // Notify player that charge is restored (only if it was used)
    if (bWasUsed && Owner != None)
    {
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("Lernaean Immortality charge restored.", 'Event');
        }
    }
}

defaultproperties
{
    bChargeAvailable=true
    bInvulnerable=false
    bDamageBoost=false
    
    Name="Default__ZTUpgrade_Skill_LernaeanImmortality_Helper"
}
