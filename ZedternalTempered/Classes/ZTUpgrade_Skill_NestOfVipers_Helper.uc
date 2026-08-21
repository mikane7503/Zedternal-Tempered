class ZTUpgrade_Skill_NestOfVipers_Helper extends Info transient;

var KFPawn_Human Player;
var int UpgradeLevel;
var bool bCloudActive;
var bool bMovingCloudActive;
var float StationaryTime;
var float MovingCloudTimeRemaining;
var vector LastPosition;
var const float MovementThreshold;
var const float MovingCloudDuration;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        bCloudActive = false;
        bMovingCloudActive = false;
        StationaryTime = 0.0f;
        MovingCloudTimeRemaining = 0.0f;
        LastPosition = Player.Location;
        SetTimer(1.0f, True);
    }
}

function Timer()
{
    local vector CurrentPosition;
    local float MovementDistance;
    local float TriggerTime;
    
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }
    
    CurrentPosition = Player.Location;
    MovementDistance = VSize(CurrentPosition - LastPosition);
    
    // Get trigger time from the skill config (INI section
    // [ZedternalTempered.ZTUpgrade_Skill_NestOfVipers]). Previously
    // hardcoded here, so the config value was ignored.
    TriggerTime = class'ZTUpgrade_Skill_NestOfVipers'.default.TriggerTime[Clamp(UpgradeLevel, 1, class'ZTUpgrade_Skill_NestOfVipers'.default.TriggerTime.Length) - 1];
    
    // Check if player is moving
    if (MovementDistance > MovementThreshold)
    {
        // Player is moving - reset stationary time
        if (bCloudActive)
        {
            // If deluxe version, activate moving cloud
            if (UpgradeLevel == 2)
            {
                ActivateMovingCloud();
            }
            else
            {
                DeactivateCloud();
            }
        }
        
        StationaryTime = 0.0f;
        LastPosition = CurrentPosition;
    }
    else
    {
        // Player is stationary - increment time
        StationaryTime += 1.0f;
        
        // Check if we should activate the cloud
        if (!bCloudActive && StationaryTime >= TriggerTime)
        {
            ActivateStationaryCloud();
        }
    }
    
    // Update moving cloud timer
    if (bMovingCloudActive)
    {
        MovingCloudTimeRemaining -= 1.0f;
        if (MovingCloudTimeRemaining <= 0.0f)
        {
            DeactivateMovingCloud();
        }
    }
    
    // Apply poison damage if either cloud is active
    if (bCloudActive || bMovingCloudActive)
    {
        ApplyPoisonCloudDamage();
    }
}

function ActivateStationaryCloud()
{
    local KFPlayerController KFPC;
    
    bCloudActive = true;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Important - skill activation
        class'ZTMessageManager'.static.SendImportant(KFPC, "Nest of Vipers: Poison cloud activated!");
    }
}

function ActivateMovingCloud()
{
    local KFPlayerController KFPC;
    
    bCloudActive = false;
    bMovingCloudActive = true;
    MovingCloudTimeRemaining = MovingCloudDuration;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Important - skill transition
        class'ZTMessageManager'.static.SendImportant(KFPC, "Nest of Vipers: Poison cloud follows you for " $ int(MovingCloudDuration) $ " seconds!");
    }
}

function DeactivateCloud()
{
    bCloudActive = false;
}

function DeactivateMovingCloud()
{
    local KFPlayerController KFPC;
    
    bMovingCloudActive = false;
    MovingCloudTimeRemaining = 0.0f;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        // Minor - buff expiration
        class'ZTMessageManager'.static.SendMinor(KFPC, "Nest of Vipers: Moving poison cloud dissipated");
    }
}

function ApplyPoisonCloudDamage()
{
    local KFPawn_Monster NearbyMonster;
    local array<KFPawn_Monster> AffectedMonsters;
    local float CloudRange, Distance;
    local int CloudDamage;
    local int i;
    local KFPlayerController KFPC;
    
    if (Player == None || Player.Controller == None) return;
    
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC == None) return;
    
    // Get cloud parameters from the skill config (INI section
    // [ZedternalTempered.ZTUpgrade_Skill_NestOfVipers]). Previously
    // hardcoded here, so the config values were ignored.
    i = Clamp(UpgradeLevel, 1, class'ZTUpgrade_Skill_NestOfVipers'.default.CloudRange.Length) - 1;
    CloudRange = class'ZTUpgrade_Skill_NestOfVipers'.default.CloudRange[i];
    CloudDamage = class'ZTUpgrade_Skill_NestOfVipers'.default.CloudDamage[Clamp(UpgradeLevel, 1, class'ZTUpgrade_Skill_NestOfVipers'.default.CloudDamage.Length) - 1];
    
    // Find all monsters within cloud range
    foreach Player.CollidingActors(class'KFPawn_Monster', NearbyMonster, CloudRange)
    {
        if (NearbyMonster != None && NearbyMonster.Health > 0)
        {
            Distance = VSize(NearbyMonster.Location - Player.Location);
            if (Distance <= CloudRange)
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
            AffectedMonsters[i].TakeDamage(CloudDamage, Player.Controller, AffectedMonsters[i].Location, vect(0,0,0), class'ZTDT_Medusa_Poison');
        }
    }
}

defaultproperties
{
    UpgradeLevel=1
    bCloudActive=false
    bMovingCloudActive=false
    StationaryTime=0.0f
    MovingCloudTimeRemaining=0.0f
    MovementThreshold=100.0f        // Movement threshold to detect if player is moving
    MovingCloudDuration=10.0f       // 10 seconds for moving cloud (Deluxe only)
    
    Name="Default__ZTUpgrade_Skill_NestOfVipers_Helper"
}