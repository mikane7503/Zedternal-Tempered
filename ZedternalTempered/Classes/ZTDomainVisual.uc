// ===================================================================
// ZTDomainVisual - cosmetic translucent dome for the Domain room.
//
// Server-spawned by ZTUpgrade_Perk_Domain_Helper.CastRoom at the room centre;
// bAlwaysRelevant so every player sees it. It scales a sphere mesh from tiny up
// to the room radius over ExpandDuration (the "expands outward" effect), then
// holds. Growth is timer-driven and only begins once the radius is actually set
// (Setup on the server, ReplicatedEvent on clients) - this avoids the earlier
// bug where PostBeginPlay started the grow before the radius existed.
//
// GEOMETRY: engine stock sphere. MeshBaseRadius must match its real radius
// (EngineMeshes.Sphere ~32 UU). MATERIAL: M_DomainDome (translucent).
// ===================================================================
class ZTDomainVisual extends Actor;

var StaticMeshComponent MeshComp;

// Replicated setup (sent once on spawn).
var repnotify vector RoomCenter;
var repnotify float  TargetRadius;
var repnotify float  ExpandDuration;
var repnotify float  HoldDuration;

// Radius of the source sphere mesh, in UU, at DrawScale 1.0.
var float MeshBaseRadius;

// runtime
var float LocalStartTime;
var bool  bExpanding;
var bool  bCalibrated;

const GROW_STEP = 0.02f;
const START_FRAC = 0.08f;

replication
{
	if (bNetInitial)
		RoomCenter, TargetRadius, ExpandDuration, HoldDuration;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'TargetRadius' || VarName == 'RoomCenter' || VarName == 'ExpandDuration')
	{
		if (TargetRadius > 0.0f && !bExpanding)
			BeginGrow();
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

// Server entry, called right after Spawn by the helper.
function Setup(vector InCenter, float InRadius, float InExpand, float InHold, float InFailsafeLife)
{
	RoomCenter = InCenter;
	TargetRadius = InRadius;
	ExpandDuration = InExpand;
	HoldDuration = InHold;

	SetLocation(RoomCenter);
	bForceNetUpdate = true;

	if (InFailsafeLife > 0.0f)
		LifeSpan = InFailsafeLife;

	BeginGrow();
}

simulated function BeginGrow()
{
	if (TargetRadius <= 0.0f)
		return;

	SetLocation(RoomCenter);
	bExpanding = true;

	// One-time calibration: measure the sphere mesh's true radius BEFORE any
	// scaling so the dome is drawn at exactly RoomRadius (otherwise it renders
	// bigger than the real room and you fall outside the gameplay radius while
	// still looking inside the dome). Hide it and hold DrawScale at 1.0 for a
	// beat so the bounds are valid, then start the normal growth.
	if (!bCalibrated && MeshComp != None)
	{
		SetHidden(true);
		SetDrawScale(1.0f);
		SetTimer(0.1f, false, nameof(CalibrateThenGrow));
		return;
	}

	StartGrowth();
}

// Read the mesh's real radius at DrawScale 1.0 (BoxExtent is the half-size and
// is position-independent), then begin growing. Falls back to the default if
// bounds aren't ready.
simulated function CalibrateThenGrow()
{
	local float R;

	if (MeshComp != None)
	{
		R = MeshComp.Bounds.BoxExtent.X;
		if (R > 1.0f)
			MeshBaseRadius = R;
	}
	bCalibrated = true;

	`log("Domain: calibrated MeshBaseRadius=" $ MeshBaseRadius $ " TargetRadius=" $ TargetRadius $ " -> DrawScale=" $ (TargetRadius / MeshBaseRadius));

	SetHidden(false);
	StartGrowth();
}

simulated function StartGrowth()
{
	// Clock starts now so the hold/expand phases time from first appearance.
	LocalStartTime = WorldInfo.TimeSeconds;

	// Start small (and hold), then drive growth with a timer.
	ApplyRadius(START_FRAC * TargetRadius);
	SetTimer(GROW_STEP, true, nameof(GrowTick));
}

simulated function GrowTick()
{
	local float Elapsed, Alpha, StartR, CurRadius;

	if (TargetRadius <= 0.0f)
		return;

	StartR = START_FRAC * TargetRadius;
	Elapsed = WorldInfo.TimeSeconds - LocalStartTime;

	// Phase 1: hold small.
	if (Elapsed < HoldDuration)
	{
		ApplyRadius(StartR);
		return;
	}

	// Phase 2: expand to full over ExpandDuration.
	if (ExpandDuration > 0.0f)
		Alpha = FClamp((Elapsed - HoldDuration) / ExpandDuration, 0.0f, 1.0f);
	else
		Alpha = 1.0f;

	CurRadius = StartR + (TargetRadius - StartR) * Alpha;
	ApplyRadius(CurRadius);

	if (Alpha >= 1.0f)
	{
		bExpanding = false;
		ClearTimer(nameof(GrowTick));
	}
}

simulated function ApplyRadius(float CurRadius)
{
	if (MeshBaseRadius > 0.0f)
		SetDrawScale(CurRadius / MeshBaseRadius);
}

simulated event Destroyed()
{
	ClearTimer(nameof(GrowTick));
	Super.Destroyed();
}

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=DomeMesh
		StaticMesh=StaticMesh'EngineMeshes.Sphere'
		Materials(0)=Material'ZedternalRBPerkpackage_Resources.Materials.M_DomainDome'
		CollideActors=false
		BlockActors=false
		CastShadow=false
		bAcceptsDynamicLights=false
		bAcceptsStaticDecals=false
		bAcceptsDynamicDecals=false
		HiddenGame=false
	End Object
	Components.Add(DomeMesh)
	MeshComp=DomeMesh

	MeshBaseRadius=32.0

	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bReplicateMovement=false
	bNetInitial=true
	bHidden=false
	bCollideActors=false
	bBlockActors=false
	Physics=PHYS_None

	Name="Default__ZTDomainVisual"
}
