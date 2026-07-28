class DKUpgrade_Skill_CurseOfStone_Helper extends Info
    transient;

var KFPawn_Human Player;
var int UpgradeLevel;

struct CursedMonster
{
    var KFPawn_Monster Monster;
    var float CurseEndTime;
};

var array<CursedMonster> CursedMonsters;
var const float CurseDuration;
var const float SpreadRange;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        SetTimer(1.0f, True);
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
    
    // Clean up expired curses
    CleanupExpiredCurses(CurrentTime);
}

function CurseMonster(KFPawn_Monster Monster, int SkillLevel)
{
    local CursedMonster NewCursed;
    local float CurrentTime;
    local KFPlayerController KFPC;
    local int ExistingIndex;
    
    if (Monster == None || Monster.Health <= 0) return;
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    
    // Check if monster is already cursed
    ExistingIndex = FindCursedMonster(Monster);
    if (ExistingIndex != INDEX_NONE)
    {
        // Refresh curse duration
        CursedMonsters[ExistingIndex].CurseEndTime = CurrentTime + CurseDuration;
    }
    else
    {
        // Add new cursed monster
        NewCursed.Monster = Monster;
        NewCursed.CurseEndTime = CurrentTime + CurseDuration;
        CursedMonsters.AddItem(NewCursed);
    }
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Minor - status effect notification
        class'DKMessageManager'.static.SendMinor(KFPC, "Curse of Stone: " $ Monster.GetLocalizedName() $ " cursed for " $ int(CurseDuration) $ " seconds!");
    }
}

function bool IsMonsterCursed(KFPawn_Monster Monster)
{
    local float CurrentTime;
    local int Index;
    
    if (Monster == None) return false;
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    Index = FindCursedMonster(Monster);
    
    if (Index != INDEX_NONE)
    {
        // Check if curse is still active
        if (CurrentTime <= CursedMonsters[Index].CurseEndTime)
        {
            return true;
        }
        else
        {
            // Remove expired curse
            CursedMonsters.Remove(Index, 1);
            return false;
        }
    }
    
    return false;
}

function SpreadCurseOnDeath(KFPawn_Monster DyingMonster)
{
    local KFPawn_Monster NearbyMonster;
    local array<KFPawn_Monster> NearbyMonsters;
    local float Distance;
    local int i, CursesSpread;
    local KFPlayerController KFPC;
    
    if (DyingMonster == None || UpgradeLevel != 2) return;
    
    // Find all monsters within spread range
    foreach DyingMonster.CollidingActors(class'KFPawn_Monster', NearbyMonster, SpreadRange)
    {
        if (NearbyMonster != DyingMonster && NearbyMonster.Health > 0 && !IsMonsterCursed(NearbyMonster))
        {
            Distance = VSize(NearbyMonster.Location - DyingMonster.Location);
            if (Distance <= SpreadRange)
            {
                NearbyMonsters.AddItem(NearbyMonster);
            }
        }
    }
    
    // Curse nearby monsters
    for (i = 0; i < NearbyMonsters.Length; i++)
    {
        CurseMonster(NearbyMonsters[i], UpgradeLevel);
        CursesSpread++;
    }
    
    // Show notification if any curses were spread
    if (CursesSpread > 0)
    {
        KFPC = KFPlayerController(Player.Controller);
        if (KFPC != None)
        {
            // Important - special effect spreading
            class'DKMessageManager'.static.SendImportant(KFPC, "Curse of Stone: Curse spread to " $ CursesSpread $ " nearby enemies!");
        }
    }
}

function int FindCursedMonster(KFPawn_Monster Monster)
{
    local int i;
    
    for (i = 0; i < CursedMonsters.Length; i++)
    {
        if (CursedMonsters[i].Monster == Monster)
        {
            return i;
        }
    }
    
    return INDEX_NONE;
}

function CleanupExpiredCurses(float CurrentTime)
{
    local int i;
    local array<CursedMonster> NewCursedMonsters;
    
    // Keep only active curses
    for (i = 0; i < CursedMonsters.Length; i++)
    {
        if (CurrentTime <= CursedMonsters[i].CurseEndTime && 
            CursedMonsters[i].Monster != None && 
            CursedMonsters[i].Monster.Health > 0)
        {
            NewCursedMonsters.AddItem(CursedMonsters[i]);
        }
    }
    
    CursedMonsters = NewCursedMonsters;
}

defaultproperties
{
    UpgradeLevel=1
    CurseDuration=5.0f              // 5 seconds curse duration
    SpreadRange=400.0f              // 4m spread range for curse spreading
    
    Name="Default__DKUpgrade_Skill_CurseOfStone_Helper"
}