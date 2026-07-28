// ===================================================================
// DKUpgrade_Skill_Reclamation_Helper — Kill Dedup + Healing
//
// Handles kill deduplication and applies health/armor recovery
// when the player gets a kill with a ★ Reforged weapon.
// Spawned as child actor of KFPawn_Human (server-side).
// ===================================================================
class DKUpgrade_Skill_Reclamation_Helper extends Info;

var int UpgradeLevel;
var KFPawn_Human Player;

// Kill deduplication
struct SKillRecord
{
    var KFPawn_Monster Monster;
    var float KillTime;
};
var array<SKillRecord> RecentKills;
var const float KillDedupeWindow;
var float LastCleanupTime;

// ===================================================================
// INITIALIZATION
// ===================================================================

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    LastCleanupTime = Owner.WorldInfo.TimeSeconds;
}

// ===================================================================
// ON KILL — Called from DKUpgrade_Skill_Reclamation.ModifyDamageGiven
// ===================================================================

function OnReforgedKill(KFPawn_Monster KilledMonster, int HealAmount, int ArmorAmount)
{
    local float CurrentTime;
    local SKillRecord NewRecord;

    if (Player == None || Player.Health <= 0 || KilledMonster == None)
        return;

    CurrentTime = Owner.WorldInfo.TimeSeconds;

    // Deduplication check
    if (IsRecentKill(KilledMonster, CurrentTime))
        return;

    // Record for deduplication
    NewRecord.Monster = KilledMonster;
    NewRecord.KillTime = CurrentTime;
    RecentKills.AddItem(NewRecord);

    // Periodic cleanup
    if (CurrentTime - LastCleanupTime > 2.0f)
    {
        CleanupOldKills(CurrentTime);
        LastCleanupTime = CurrentTime;
    }

    // Apply healing
    if (Player.Health < Player.HealthMax)
    {
        // Heal HP
        Player.HealDamage(HealAmount, Player.Controller, class'KFDT_Healing');
    }
    else
    {
        // At full HP — recover armor instead
        if (WMPawn_Human(Player) != None)
        {
            WMPawn_Human(Player).ZedternalArmor = Min(
                WMPawn_Human(Player).ZedternalArmor + ArmorAmount,
                WMPawn_Human(Player).ZedternalMaxArmor
            );
        }
    }
}

// ===================================================================
// KILL DEDUPLICATION
// ===================================================================

function bool IsRecentKill(KFPawn_Monster Monster, float CurrentTime)
{
    local int i;

    for (i = 0; i < RecentKills.Length; ++i)
    {
        if (RecentKills[i].Monster == Monster && (CurrentTime - RecentKills[i].KillTime) <= KillDedupeWindow)
            return True;
    }

    return False;
}

function CleanupOldKills(float CurrentTime)
{
    local int i;
    local array<SKillRecord> Cleaned;

    for (i = 0; i < RecentKills.Length; ++i)
    {
        if ((CurrentTime - RecentKills[i].KillTime) <= 1.0f)
            Cleaned.AddItem(RecentKills[i]);
    }

    RecentKills = Cleaned;
}

defaultproperties
{
    RemoteRole=ROLE_None
    bAlwaysRelevant=False
    bOnlyRelevantToOwner=True
    bHidden=True
    bCollideActors=False
    bBlockActors=False

    UpgradeLevel=1
    KillDedupeWindow=0.03f
    LastCleanupTime=0.0f

    Name="Default__DKUpgrade_Skill_Reclamation_Helper"
}
