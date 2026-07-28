class DKUpgrade_Skill_PetrifyingPresence_Helper extends Info
    transient;

var KFPawn_Human Player;
var int UpgradeLevel;

struct PetrifiedMonster
{
    var KFPawn_Monster Monster;
    var float PetrifyEndTime;
};

var array<PetrifiedMonster> PetrifiedMonsters;
var const float PetrifyDuration;

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
    
    // Clean up expired petrified monsters
    CleanupExpiredPetrifications(CurrentTime);
}

function PetrifyMonster(KFPawn_Monster Monster, int SkillLevel)
{
    local PetrifiedMonster NewPetrified;
    local float CurrentTime;
    local int ExistingIndex;
    
    if (Monster == None || Monster.Health <= 0) return;
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    
    // Check if monster is already petrified
    ExistingIndex = FindPetrifiedMonster(Monster);
    if (ExistingIndex != INDEX_NONE)
    {
        // Refresh petrify duration
        PetrifiedMonsters[ExistingIndex].PetrifyEndTime = CurrentTime + PetrifyDuration;
    }
    else
    {
        // Add new petrified monster
        NewPetrified.Monster = Monster;
        NewPetrified.PetrifyEndTime = CurrentTime + PetrifyDuration;
        PetrifiedMonsters.AddItem(NewPetrified);
    }
    
    // Apply petrification effects. NOTE: the petrify proc no longer prints a
    // per-hit notification -- it fired on every proc (10-20% of hits) and leaked
    // raw zed names / localization keys through GetLocalizedName() on custom zeds.
    ApplyPetrificationEffects(Monster, SkillLevel);
}

function ApplyPetrificationEffects(KFPawn_Monster Monster, int SkillLevel)
{
    // Real petrify CC: force a directional Stumble on the proc'd zed, mirroring the
    // engine's own parry-stumble path. Restricted to non-large / non-boss zeds --
    // DoSpecialMove(SM_Stumble) bypasses the normal stumble-power accumulation, so
    // without this guard it would hard-lock Scrakes, Fleshpounds and bosses on every
    // proc. Large/boss targets still receive the petrify mark (and thus the Deluxe
    // +50% damage-taken) -- just not the stagger. CanDoSpecialMove gates repeats: a
    // zed already stumbling won't re-trigger, so high-RoF weapons can't spam it.
    if (Monster == None || Monster.Health <= 0 || Player == None)
        return;

    if (Monster.IsLargeZed() || Monster.IsABoss() || KFInterface_MonsterBoss(Monster) != None)
        return;

    if (Monster.CanDoSpecialMove(SM_Stumble))
    {
        Monster.DoSpecialMove(SM_Stumble, , ,
            class'KFSM_Stumble'.static.PackParrySMFlags(Monster, Monster.Location - Player.Location));
    }
}

function bool IsMonsterPetrified(KFPawn_Monster Monster)
{
    local float CurrentTime;
    local int Index;
    
    if (Monster == None) return false;
    
    CurrentTime = Player.WorldInfo.TimeSeconds;
    Index = FindPetrifiedMonster(Monster);
    
    if (Index != INDEX_NONE)
    {
        // Check if petrification is still active
        if (CurrentTime <= PetrifiedMonsters[Index].PetrifyEndTime)
        {
            return true;
        }
        else
        {
            // Remove expired petrification
            PetrifiedMonsters.Remove(Index, 1);
            return false;
        }
    }
    
    return false;
}

function int FindPetrifiedMonster(KFPawn_Monster Monster)
{
    local int i;
    
    for (i = 0; i < PetrifiedMonsters.Length; i++)
    {
        if (PetrifiedMonsters[i].Monster == Monster)
        {
            return i;
        }
    }
    
    return INDEX_NONE;
}

function CleanupExpiredPetrifications(float CurrentTime)
{
    local int i;
    local array<PetrifiedMonster> NewPetrifiedMonsters;
    
    // Keep only active petrifications
    for (i = 0; i < PetrifiedMonsters.Length; i++)
    {
        if (CurrentTime <= PetrifiedMonsters[i].PetrifyEndTime && PetrifiedMonsters[i].Monster != None && PetrifiedMonsters[i].Monster.Health > 0)
        {
            NewPetrifiedMonsters.AddItem(PetrifiedMonsters[i]);
        }
    }
    
    PetrifiedMonsters = NewPetrifiedMonsters;
}

defaultproperties
{
    UpgradeLevel=1
    PetrifyDuration=3.0f            // 3 seconds of petrification effect
    
    Name="Default__DKUpgrade_Skill_PetrifyingPresence_Helper"
}