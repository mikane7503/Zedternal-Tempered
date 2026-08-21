class ZTUpgrade_Skill_Overkill_Helper extends Info;

var int StoredExcessDamage;
var float LastStorageTime;
var float StorageDecayTime;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Owner == None)
        Destroy();
    
    StoredExcessDamage = 0;
    LastStorageTime = 0.0f;
}

function StoreDamage(int Damage)
{
    local KFPlayerController KFPC;
    
    if (Owner == None)
        return;
    
    StoredExcessDamage = Damage;
    LastStorageTime = Owner.WorldInfo.TimeSeconds;
    
    // Set decay timer - stored damage expires after some time
    SetTimer(StorageDecayTime, false, 'DecayStoredDamage');
    
    // Notify player
    if (Damage > 0)
    {
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("Overkill: +" $ Damage $ " damage stored!", 'Event');
        }
    }
}

function int ConsumeStoredDamage()
{
    local int Damage;
    local KFPlayerController KFPC;
    
    // Check if stored damage has expired
    if (StoredExcessDamage > 0 && Owner != None)
    {
        if ((Owner.WorldInfo.TimeSeconds - LastStorageTime) > StorageDecayTime)
        {
            StoredExcessDamage = 0;
        }
    }
    
    Damage = StoredExcessDamage;
    StoredExcessDamage = 0;
    
    // Clear decay timer since we consumed it
    ClearTimer('DecayStoredDamage');
    
    // Notify player if damage was consumed
    if (Damage > 0 && Owner != None)
    {
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("Overkill applied: +" $ Damage $ " bonus damage!", 'Event');
        }
    }
    
    return Damage;
}

function DecayStoredDamage()
{
    local KFPlayerController KFPC;
    
    if (StoredExcessDamage > 0 && Owner != None)
    {
        KFPC = KFPlayerController(Pawn(Owner).Controller);
        if (KFPC != None)
        {
            KFPC.ClientMessage("Overkill damage expired.", 'Event');
        }
    }
    
    StoredExcessDamage = 0;
}

function int GetStoredDamage()
{
    return StoredExcessDamage;
}

defaultproperties
{
    StoredExcessDamage=0
    LastStorageTime=0.0f
    StorageDecayTime=5.0f
    
    Name="Default__ZTUpgrade_Skill_Overkill_Helper"
}
