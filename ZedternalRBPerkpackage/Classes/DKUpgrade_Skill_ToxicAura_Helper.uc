class DKUpgrade_Skill_ToxicAura_Helper extends Info
    transient;

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
    
    // Get aura parameters from the skill config (INI section
    // [ZedternalRBPerkpackage.DKUpgrade_Skill_ToxicAura]). These were
    // previously hardcoded here, so the config values were ignored.
    i = Clamp(UpgradeLevel, 1, class'DKUpgrade_Skill_ToxicAura'.default.AuraRange.Length) - 1;
    AuraRange = class'DKUpgrade_Skill_ToxicAura'.default.AuraRange[i];
    AuraDamage = class'DKUpgrade_Skill_ToxicAura'.default.AuraDamage[Clamp(UpgradeLevel, 1, class'DKUpgrade_Skill_ToxicAura'.default.AuraDamage.Length) - 1];
    
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
            AffectedMonsters[i].TakeDamage(AuraDamage, Player.Controller, AffectedMonsters[i].Location, vect(0,0,0), class'DKDT_Medusa_Poison');
        }
    }
    
    // Show notification if any monsters were affected (Minor - continuous effect)
    if (AffectedMonsters.Length > 0)
    {
        class'DKMessageManager'.static.SendMinor(KFPC, "Toxic Aura: Poisoning " $ AffectedMonsters.Length $ " enemies");
    }
}

defaultproperties
{
    UpgradeLevel=1
    AuraCheckInterval=1.0f          // Check for aura damage every 1 second
    LastAuraCheckTime=0.0f
    
    Name="Default__DKUpgrade_Skill_ToxicAura_Helper"
}