class DKUpgrade_Skill_ThermalDrill_Helper extends Info
    transient;

struct ThermalTarget
{
    var KFPawn_Monster Target;
    var int HeatStacks;
    var float LastHitTime;
};

var array<ThermalTarget> HeatTargets;
var const ParticleSystem PSHeatEffect;
var const AkBaseSoundObject HeatSound;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Owner == None)
        Destroy();
    else
        SetTimer(1.0f, True, NameOf(UpdateHeatStacks));
}

function int GetHeatStacks(KFPawn_Monster Target)
{
    local int i;
    
    if (Target == None)
        return 0;
        
    for (i = 0; i < HeatTargets.Length; i++)
    {
        if (HeatTargets[i].Target == Target)
        {
            return HeatTargets[i].HeatStacks;
        }
    }
    
    return 0;
}

function AddHeatStack(KFPawn_Monster Target, int SkillLevel)
{
    local int i, MaxStacks;
    local ThermalTarget NewTarget;
    local bool bFoundTarget;
    
    if (Target == None || !Target.IsAliveAndWell())
        return;
        
    // Get skill parameters based on level
    if (SkillLevel == 1)
    {
        MaxStacks = 5;
    }
    else
    {
        MaxStacks = 8;
    }
    
    bFoundTarget = False;
    
    // Find existing target or create new one
    for (i = 0; i < HeatTargets.Length; i++)
    {
        if (HeatTargets[i].Target == Target)
        {
            HeatTargets[i].HeatStacks = Min(HeatTargets[i].HeatStacks + 1, MaxStacks);
            HeatTargets[i].LastHitTime = WorldInfo.TimeSeconds;
            bFoundTarget = True;
            
            // Play heat effect if we're at max stacks
            if (HeatTargets[i].HeatStacks >= MaxStacks)
            {
                PlayHeatEffect(Target);
            }
            break;
        }
    }
    
    if (!bFoundTarget)
    {
        NewTarget.Target = Target;
        NewTarget.HeatStacks = 1;
        NewTarget.LastHitTime = WorldInfo.TimeSeconds;
        HeatTargets.AddItem(NewTarget);
    }
}

function UpdateHeatStacks()
{
    local int i;
    local float StackDuration;
    
    // Clean up dead targets and expired stacks
    for (i = HeatTargets.Length - 1; i >= 0; i--)
    {
        if (HeatTargets[i].Target == None || !HeatTargets[i].Target.IsAliveAndWell())
        {
            HeatTargets.Remove(i, 1);
            continue;
        }
        
        // Determine stack duration (assume level 2 if stacks > 5, otherwise level 1)
        StackDuration = (HeatTargets[i].HeatStacks > 5) ? 6.0f : 4.0f;
        
        if (WorldInfo.TimeSeconds - HeatTargets[i].LastHitTime > StackDuration)
        {
            HeatTargets[i].HeatStacks--;
            if (HeatTargets[i].HeatStacks <= 0)
            {
                HeatTargets.Remove(i, 1);
            }
        }
    }
    
    // Destroy helper if no targets
    if (HeatTargets.Length == 0 && Owner == None)
    {
        Destroy();
    }
}

reliable client function PlayHeatEffect(KFPawn_Monster Target)
{
    local vector Loc;
    local rotator Rot;
    local ParticleSystemComponent PSC;
    local PlayerController PC;
    
    PC = GetALocalPlayerController();
    
    if (PC == None || Target == None)
        return;
        
    // Play heat sound
    Target.PlaySoundBase(HeatSound, False);
    
    // Spawn heat effect on target
    Loc = Target.Location;
    Loc.Z += Target.GetCollisionHeight() * 0.5f;
    Rot = Target.Rotation;
    
    PSC = Target.WorldInfo.MyEmitterPool.SpawnEmitter(PSHeatEffect, Loc, Rot);
    if (PSC != None)
    {
        PSC.SetDepthPriorityGroup(SDPG_World);
        // Attach to target so it follows them - using AttachToActor instead of SetBase
        PSC.SetLODLevel(0);
    }
}

defaultproperties
{
    bOnlyRelevantToOwner=True
    
    PSHeatEffect=ParticleSystem'ZedternalReborn_Resource.Effects.FX_BringTheHeat_Effect'
    HeatSound=AkEvent'WW_WEP_Bullet_Impacts.Play_Bullet_Impact_Metal'
    
    Name="Default__DKUpgrade_Skill_ThermalDrill_Helper"
}