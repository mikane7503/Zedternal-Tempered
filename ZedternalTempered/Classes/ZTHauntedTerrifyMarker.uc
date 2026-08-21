// Four-second target marker used by The Watcher's Gift.
class ZTHauntedTerrifyMarker extends Info;

const TERRIFY_DURATION = 4.0f;

var KFPawn_Monster Target;

function Initialize(KFPawn_Monster InTarget)
{
    Target = InTarget;
    if (Target == None || !Target.IsAliveAndWell())
    {
        Destroy();
        return;
    }

    // Keep the engine's native panic-wander AI command alive even if another
    // zed command temporarily interrupts and resumes it.
    Target.bPlayPanicked = true;
    Target.CausePanicWander();

    RefreshTerrify();
}

function RefreshTerrify()
{
    if (Target == None || !Target.IsAliveAndWell())
    {
        Destroy();
        return;
    }

    SetTimer(TERRIFY_DURATION, false, nameof(ExpireTerrify));
}

function ExpireTerrify()
{
    if (Target != None && Target.IsAliveAndWell())
    {
        // Do not cancel native fire, poison, microwave, EMP, or headless panic.
        Target.bPlayPanicked = Target.bFirePanicked || Target.bIsPoisoned || Target.bMicrowavePanicked;
        if (!Target.ShouldBeWandering())
            Target.EndPanicWander();
    }

    Destroy();
}

event Destroyed()
{
    ClearTimer(nameof(ExpireTerrify));
    Target = None;
    Super.Destroyed();
}

defaultproperties
{
    RemoteRole=ROLE_None
    bHidden=true
    bCollideActors=false
    bBlockActors=false
    bProjTarget=false
    Name="Default__ZTHauntedTerrifyMarker"
}
