// ===================================================================
// DKUpgrade_Skill_ChronoCarapace_Helper
// Monitors ZED Time state transitions. When ZED Time ends, activates
// a lingering damage reduction flag for a configurable duration.
// Pattern: WMUpgrade_Skill_Destruction_Helper
// ===================================================================
class DKUpgrade_Skill_ChronoCarapace_Helper extends Info
	transient;

var KFPawn_Human Player;
var bool bLingeringProtection;
var bool bInZedTime;
var const float Update;
var const float LingerDuration;

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
	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	if (Player.WorldInfo.TimeDilation < 1.0)
	{
		bInZedTime = True;
	}
	else if (bInZedTime)
	{
		// ZED Time just ended - activate lingering protection
		bInZedTime = False;
		bLingeringProtection = True;
		ClearTimer(NameOf(EndLingeringProtection));
		SetTimer(LingerDuration, False, NameOf(EndLingeringProtection));
	}
}

function EndLingeringProtection()
{
	bLingeringProtection = False;
}

defaultproperties
{
	bLingeringProtection=False
	bInZedTime=False
	Update=0.25f
	LingerDuration=3.0f

	Name="Default__DKUpgrade_Skill_ChronoCarapace_Helper"
}
