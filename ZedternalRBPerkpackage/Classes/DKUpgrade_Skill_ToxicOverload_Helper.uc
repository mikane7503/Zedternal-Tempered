// Helper for Toxic Overload.
// Tracks the last-damaged ZED's location and poisoned status.
// When a kill happens (via AddVampireHealth), spawns a toxic explosion
// at the cached location if the target was poisoned.
class DKUpgrade_Skill_ToxicOverload_Helper extends Info
	transient;

var KFPawn_Human Player;
var vector LastTargetLocation;
var bool bLastTargetPoisoned;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function UpdateTarget(KFPawn_Monster Target)
{
	if (Target != None)
	{
		LastTargetLocation = Target.Location;
		bLastTargetPoisoned = Target.bIsPoisoned;
	}
}

function TriggerExplosion()
{
	local DKExplosion_ToxicOverload ExploActor;

	if (bLastTargetPoisoned && Player != None && Player.Controller != None)
	{
		ExploActor = Spawn(class'ZedternalRBPerkpackage.DKExplosion_ToxicOverload', Player, , LastTargetLocation, rotator(vect(0, 0, 1)));
		if (ExploActor != None)
		{
			ExploActor.InstigatorController = Player.Controller;
			ExploActor.Instigator = Player;
		}
		bLastTargetPoisoned = False;
	}
}

defaultproperties
{
	bLastTargetPoisoned=False

	Name="Default__DKUpgrade_Skill_ToxicOverload_Helper"
}
