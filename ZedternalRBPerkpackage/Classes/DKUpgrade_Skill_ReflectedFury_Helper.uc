class DKUpgrade_Skill_ReflectedFury_Helper extends Info;

var KFPawn_Human Player;
var bool bReady;
var bool bDeluxe;
var float Cooldown;
var float LastTriggerTime;

var const class<DamageType> ReflectDamageType;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    
    bReady = true;
    LastTriggerTime = 0.0f;
}

function bool IsReady()
{
    local float CurrentTime;
    
    if (!bReady)
    {
        CurrentTime = Player.WorldInfo.TimeSeconds;
        if ((CurrentTime - LastTriggerTime) >= Cooldown)
        {
            bReady = true;
        }
    }
    
    return bReady;
}

function TriggerReflection(int Damage, float Radius)
{
    local KFPawn_Monster KFPM;
    local float DistSq;
    local float RadiusSq;
    local KFPlayerController KFPC;
    local int EnemiesHit;
    
    if (Player == None || Player.Health <= 0)
        return;
    
    // Start cooldown
    bReady = false;
    LastTriggerTime = Player.WorldInfo.TimeSeconds;
    SetTimer(Cooldown, false, 'ResetCooldown');
    
    // Find and damage all monsters within radius
    RadiusSq = Radius * Radius;
    EnemiesHit = 0;
    
    foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
    {
        if (KFPM != None && KFPM.IsAliveAndWell())
        {
            DistSq = VSizeSq(KFPM.Location - Player.Location);
            if (DistSq <= RadiusSq)
            {
                // Deal damage to the monster
                KFPM.TakeDamage(Damage, Player.Controller, KFPM.Location, vect(0,0,0), ReflectDamageType);
                EnemiesHit++;
            }
        }
    }
    
    // Notify player
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        if (EnemiesHit > 0)
            KFPC.ClientMessage("Reflected Fury! Hit " $ EnemiesHit $ " enemies for " $ Damage $ " damage!", 'Event');
        else
            KFPC.ClientMessage("Reflected Fury triggered! (No enemies in range)", 'Event');
    }
}

function ResetCooldown()
{
    bReady = true;
}

defaultproperties
{
    bOnlyRelevantToOwner=True
    bReady=True
    bDeluxe=False
    Cooldown=10.0f
    LastTriggerTime=0.0f
    
    // Use a generic explosive damage type
    ReflectDamageType=class'KFDT_Explosive'
    
    Name="Default__DKUpgrade_Skill_ReflectedFury_Helper"
}
