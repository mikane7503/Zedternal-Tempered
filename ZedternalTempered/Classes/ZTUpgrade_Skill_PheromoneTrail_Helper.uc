// ===================================================================
// ZTUpgrade_Skill_PheromoneTrail_Helper
// Manages the speed buff state triggered by kills.
// When a kill occurs, bActive is set and a timer begins counting
// down. When the timer expires, the buff deactivates.
// ===================================================================
class ZTUpgrade_Skill_PheromoneTrail_Helper extends Info transient;

var KFPawn_Human Player;
var bool bActive;
var bool bDeluxe;
var const float BuffDuration;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function OnKill()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	// Activate or refresh the speed buff
	bActive = True;
	ClearTimer(nameof(DeactivateBuff));
	SetTimer(BuffDuration, False, nameof(DeactivateBuff));

	// Force speed recalculation
	Player.UpdateGroundSpeed();
}

function DeactivateBuff()
{
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	bActive = False;
	Player.UpdateGroundSpeed();
}

defaultproperties
{
	bActive=False
	bDeluxe=False
	BuffDuration=3.0f

	Name="Default__ZTUpgrade_Skill_PheromoneTrail_Helper"
}
