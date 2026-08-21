class ZTUpgrade_Skill_HuntersInstinct_Helper extends Info transient;

struct MarkedZedInfo
{
    var KFPawn_Monster Zed;
    var float ExpirationTime;
    var bool bValid;
};

var array<MarkedZedInfo> MarkedZeds;
var const float CleanupInterval;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Owner == None)
        Destroy();
    else
        SetTimer(CleanupInterval, True, NameOf(CleanupMarkedZeds));
}

function MarkNearbyZeds(vector KillLocation, float Radius, float Duration)
{
    local KFPawn_Monster KFPM;
    local float RadiusSq;
    
    RadiusSq = Radius * Radius;
    
    foreach WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
    {
        if (KFPM != None && KFPM.IsAliveAndWell() && 
            VSizeSQ(KFPM.Location - KillLocation) <= RadiusSq)
        {
            // Add or refresh mark on this zed
            AddOrRefreshMark(KFPM, Duration);
            
            // Apply visual effect
            ApplyMarkEffect(KFPM);
        }
    }
}

function AddOrRefreshMark(KFPawn_Monster Zed, float Duration)
{
    local int i;
    local MarkedZedInfo NewMark;
    
    // Check if zed is already marked
    for (i = 0; i < MarkedZeds.Length; i++)
    {
        if (MarkedZeds[i].bValid && MarkedZeds[i].Zed == Zed)
        {
            // Refresh existing mark
            MarkedZeds[i].ExpirationTime = WorldInfo.TimeSeconds + Duration;
            return;
        }
    }
    
    // Find empty slot or add new one
    for (i = 0; i < MarkedZeds.Length; i++)
    {
        if (!MarkedZeds[i].bValid)
        {
            MarkedZeds[i].Zed = Zed;
            MarkedZeds[i].ExpirationTime = WorldInfo.TimeSeconds + Duration;
            MarkedZeds[i].bValid = True;
            return;
        }
    }
    
    // No empty slots, add new one
    NewMark.Zed = Zed;
    NewMark.ExpirationTime = WorldInfo.TimeSeconds + Duration;
    NewMark.bValid = True;
    MarkedZeds.AddItem(NewMark);
}

function bool IsZedMarked(KFPawn_Monster Zed)
{
    local int i;
    
    for (i = 0; i < MarkedZeds.Length; i++)
    {
        if (MarkedZeds[i].bValid && MarkedZeds[i].Zed == Zed && 
            WorldInfo.TimeSeconds < MarkedZeds[i].ExpirationTime)
        {
            return True;
        }
    }
    
    return False;
}

function CleanupMarkedZeds()
{
    local int i;
    local float CurrentTime;
    
    CurrentTime = WorldInfo.TimeSeconds;
    
    for (i = MarkedZeds.Length - 1; i >= 0; i--)
    {
        if (!MarkedZeds[i].bValid || MarkedZeds[i].Zed == None || 
            !MarkedZeds[i].Zed.IsAliveAndWell() || 
            CurrentTime >= MarkedZeds[i].ExpirationTime)
        {
            // Remove expired or invalid marks
            if (MarkedZeds[i].bValid && MarkedZeds[i].Zed != None)
            {
                RemoveMarkEffect(MarkedZeds[i].Zed);
            }
            
            MarkedZeds[i].bValid = False;
        }
    }
}

reliable client function ApplyMarkEffect(KFPawn_Monster Zed)
{
    // Apply visual marking effect - could be outline, particle, etc.
    if (Zed != None && Zed.Mesh != None)
    {
        // Simple approach: make the zed glow red briefly
        Zed.Mesh.SetMaterial(0, Zed.Mesh.GetMaterial(0));  // Reset first
        Zed.SetTimer(0.1f, False, NameOf(Zed.ClearTimer));
        
        // Could add particle effect here if desired
        // WorldInfo.MyEmitterPool.SpawnEmitter(MarkEffect, Zed.Location);
    }
}

function RemoveMarkEffect(KFPawn_Monster Zed)
{
    // Remove any visual effects when mark expires
    if (Zed != None && Zed.Mesh != None)
    {
        // Reset materials to default
        Zed.Mesh.SetMaterial(0, None);
    }
}

function Destroyed()
{
    local int i;
    
    // Clean up any visual effects when helper is destroyed
    for (i = 0; i < MarkedZeds.Length; i++)
    {
        if (MarkedZeds[i].bValid && MarkedZeds[i].Zed != None)
        {
            RemoveMarkEffect(MarkedZeds[i].Zed);
        }
    }
    
    super.Destroyed();
}

defaultproperties
{
    bOnlyRelevantToOwner=False  // Team can see marks
    CleanupInterval=1.0f
    
    Name="Default__ZTUpgrade_Skill_HuntersInstinct_Helper"
}