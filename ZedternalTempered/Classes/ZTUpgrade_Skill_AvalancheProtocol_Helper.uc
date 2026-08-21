class ZTUpgrade_Skill_AvalancheProtocol_Helper extends Info transient;

struct SlowedTarget
{
    var KFPawn_Monster Target;
    var float SlowEndTime;
    var float OriginalGroundSpeed;
};

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var array<SlowedTarget> SlowedTargets;
var const float Update, AvalancheRadius, SlowDuration, SlowModifier, DeduplicationWindow;
var float LastAvalancheTime;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
        SetTimer(Update, True);
}

function Timer()
{
    local int i;
    local float CurrentTime;

    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    CurrentTime = Player.WorldInfo.TimeSeconds;

    // Clean up expired slows and dead targets
    for (i = SlowedTargets.Length - 1; i >= 0; i--)
    {
        if (SlowedTargets[i].Target == None || 
            !SlowedTargets[i].Target.IsAliveAndWell() ||
            CurrentTime >= SlowedTargets[i].SlowEndTime)
        {
            // Restore original speed if target is still alive
            if (SlowedTargets[i].Target != None && SlowedTargets[i].Target.IsAliveAndWell())
            {
                SlowedTargets[i].Target.GroundSpeed = SlowedTargets[i].OriginalGroundSpeed;
            }
            SlowedTargets.Remove(i, 1);
        }
    }
}

function OnEnemyKilled(KFPawn_Monster KilledEnemy)
{
    local KFPawn_Monster KFM;
    local float CurrentTime, DistanceSq;
    local int DamageAmount;

    if (KilledEnemy == None)
        return;

    CurrentTime = Player.WorldInfo.TimeSeconds;

    // Check deduplication window
    if ((CurrentTime - LastAvalancheTime) < DeduplicationWindow)
        return;

    LastAvalancheTime = CurrentTime;

    // Get damage amount based on upgrade level
    DamageAmount = class'ZTUpgrade_Skill_AvalancheProtocol'.default.AvalancheDamage[UpgradeLevel - 1];

    // Find nearby enemies and apply avalanche effect
    foreach DynamicActors(class'KFPawn_Monster', KFM)
    {
        if (KFM != None && KFM.IsAliveAndWell() && KFM != KilledEnemy)
        {
            DistanceSq = VSizeSQ(KilledEnemy.Location - KFM.Location);
            
            if (DistanceSq <= Square(AvalancheRadius))
            {
                // Apply damage
                if (DamageAmount > 0)
                {
                    KFM.TakeDamage(DamageAmount, Player.Controller, KFM.Location, vect(0,0,0), class'KFDT_Freeze');
                }

                // Apply slow effect
                ApplySlowToTarget(KFM, CurrentTime);
            }
        }
    }
}

function ApplySlowToTarget(KFPawn_Monster Target, float CurrentTime)
{
    local int i;
    local SlowedTarget NewSlowTarget;
    local bool bFoundExisting;

    if (Target == None || !Target.IsAliveAndWell())
        return;

    bFoundExisting = False;

    // Check if target is already slowed, extend duration
    for (i = 0; i < SlowedTargets.Length; i++)
    {
        if (SlowedTargets[i].Target == Target)
        {
            SlowedTargets[i].SlowEndTime = CurrentTime + SlowDuration;
            bFoundExisting = True;
            break;
        }
    }

    // If not already slowed, apply new slow
    if (!bFoundExisting)
    {
        NewSlowTarget.Target = Target;
        NewSlowTarget.SlowEndTime = CurrentTime + SlowDuration;
        NewSlowTarget.OriginalGroundSpeed = Target.GroundSpeed;
        
        // Apply slow effect
        Target.GroundSpeed = Target.GroundSpeed * SlowModifier;
        
        SlowedTargets.AddItem(NewSlowTarget);
    }
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    Update=0.5f
    AvalancheRadius=800.0f  // 8 meters in Unreal units
    SlowDuration=5.0f
    SlowModifier=0.5f       // 50% speed reduction
    DeduplicationWindow=0.1f
    LastAvalancheTime=0.0f

    Name="Default__ZTUpgrade_Skill_AvalancheProtocol_Helper"
}