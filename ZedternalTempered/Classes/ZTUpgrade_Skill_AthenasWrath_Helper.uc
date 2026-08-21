class ZTUpgrade_Skill_AthenasWrath_Helper extends Info transient;

var KFPawn_Human Player;
var int UpgradeLevel;

struct AttackerRecord
{
    var KFPawn_Monster Attacker;
    var float AttackTime;
    var class<KFPawn_Monster> AttackerClass;
};

var array<AttackerRecord> RecentAttackers;
var const float RevengeWindow;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        SetTimer(2.0f, True); // Check every 2 seconds for cleanup
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
    
    // Clean up old attacker records
    CleanupOldAttackers(CurrentTime);
}

function TrackAttacker(KFPawn_Monster Attacker, int SkillLevel)
{
    local AttackerRecord NewRecord;
    local float CurrentTime;
    local int ExistingIndex;
    local KFPlayerController KFPC;
    
    if (Attacker == None || Attacker.Health <= 0) return;
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    
    // Check if we already have this attacker tracked
    ExistingIndex = FindAttackerRecord(Attacker);
    if (ExistingIndex != INDEX_NONE)
    {
        // Update the attack time
        RecentAttackers[ExistingIndex].AttackTime = CurrentTime;
    }
    else
    {
        // Add new attacker record
        NewRecord.Attacker = Attacker;
        NewRecord.AttackTime = CurrentTime;
        NewRecord.AttackerClass = Attacker.Class;
        RecentAttackers.AddItem(NewRecord);
        
        KFPC = KFPlayerController(Player.Controller);
        if (KFPC != None)
        {
            // Minor - tracking notification
            class'ZTMessageManager'.static.SendMinor(KFPC, "Athena's Wrath: " $ Attacker.GetLocalizedName() $ " marked for revenge!");
        }
    }
}

function bool ShouldGetRevengeBonus(KFPawn_Monster Target, int SkillLevel)
{
    local float CurrentTime;
    local int i;
    local bool bDirectRevenge, bTypeRevenge;
    
    if (Target == None) return false;
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    
    // Check for direct revenge (this specific monster attacked us)
    for (i = 0; i < RecentAttackers.Length; i++)
    {
        if (RecentAttackers[i].Attacker == Target)
        {
            if (CurrentTime - RecentAttackers[i].AttackTime <= RevengeWindow)
            {
                bDirectRevenge = true;
                break;
            }
        }
    }
    
    // For Deluxe version, also check for same type revenge
    if (SkillLevel == 2 && !bDirectRevenge)
    {
        for (i = 0; i < RecentAttackers.Length; i++)
        {
            if (RecentAttackers[i].AttackerClass == Target.Class)
            {
                if (CurrentTime - RecentAttackers[i].AttackTime <= RevengeWindow)
                {
                    bTypeRevenge = true;
                    break;
                }
            }
        }
    }
    
    return (bDirectRevenge || bTypeRevenge);
}

function int FindAttackerRecord(KFPawn_Monster Attacker)
{
    local int i;
    
    for (i = 0; i < RecentAttackers.Length; i++)
    {
        if (RecentAttackers[i].Attacker == Attacker)
        {
            return i;
        }
    }
    
    return INDEX_NONE;
}

function CleanupOldAttackers(float CurrentTime)
{
    local int i;
    local array<AttackerRecord> NewRecentAttackers;
    
    // Keep only recent attackers (within revenge window and still alive)
    for (i = 0; i < RecentAttackers.Length; i++)
    {
        if (CurrentTime - RecentAttackers[i].AttackTime <= RevengeWindow && 
            RecentAttackers[i].Attacker != None && 
            RecentAttackers[i].Attacker.Health > 0)
        {
            NewRecentAttackers.AddItem(RecentAttackers[i]);
        }
    }
    
    RecentAttackers = NewRecentAttackers;
}

defaultproperties
{
    UpgradeLevel=1
    RevengeWindow=10.0f             // 10 seconds revenge window
    
    Name="Default__ZTUpgrade_Skill_AthenasWrath_Helper"
}