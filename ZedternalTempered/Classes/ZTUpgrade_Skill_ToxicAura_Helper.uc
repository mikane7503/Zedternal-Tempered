class ZTUpgrade_Skill_ToxicAura_Helper extends Info transient;

var KFPawn_Human Player;
var int UpgradeLevel;
var float AuraCheckInterval;
var float LastAuraCheckTime;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        LastAuraCheckTime = Player.WorldInfo.TimeSeconds;
        SetTimer(AuraCheckInterval, True);
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
    
    // Apply toxic aura damage to nearby enemies
    if (CurrentTime - LastAuraCheckTime >= AuraCheckInterval)
    {
        ApplyToxicAuraDamage();
        LastAuraCheckTime = CurrentTime;
    }
}

function ApplyToxicAuraDamage()
{
    local KFPawn_Monster NearbyMonster;
    local array<KFPawn_Monster> AffectedMonsters;
    local float AuraRange, Distance;
    local int AuraDamage;
    local int i;
    local KFPlayerController KFPC;
    
    if (Player == None || Player.Controller == None) return;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC == None) return;
    
    // Get aura parameters based on upgrade level
    if (UpgradeLevel == 1)
    {
        AuraRange = 300.0f; // 3m
        AuraDamage = 2;
    }
    else
    {
        AuraRange = 500.0f; // 5m
        AuraDamage = 4;
    }
    
    // Find all monsters within aura range
    foreach Player.CollidingActors(class'KFPawn_Monster', NearbyMonster, AuraRange)
    {
        if (NearbyMonster != None && NearbyMonster.Health > 0)
        {
            Distance = VSize(NearbyMonster.Location - Player.Location);
            if (Distance <= AuraRange)
            {
                AffectedMonsters.AddItem(NearbyMonster);
            }
        }
    }
    
    // Apply poison damage to affected monsters
    for (i = 0; i < AffectedMonsters.Length; i++)
    {
        if (AffectedMonsters[i] != None && AffectedMonsters[i].Health > 0)
        {
            // Apply poison damage
            AffectedMonsters[i].TakeDamage(AuraDamage, Player.Controller, AffectedMonsters[i].Location, vect(0,0,0), class'ZTDT_Medusa_Poison');
        }
    }
    
    // Show notification if any monsters were affected (Minor - continuous effect)
    if (AffectedMonsters.Length > 0)
    {
        class'ZTMessageManager'.static.SendMinor(KFPC, "Toxic Aura: Poisoning " $ AffectedMonsters.Length $ " enemies");
    }
}

defaultproperties
{
    UpgradeLevel=1
    AuraCheckInterval=1.0f          // Check for aura damage every 1 second
    LastAuraCheckTime=0.0f
    
    Name="Default__ZTUpgrade_Skill_ToxicAura_Helper"
}