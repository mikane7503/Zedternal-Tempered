// Designated Hitter helper - polls for the Fastball payload marker on the owner;
// when the marker disappears after having been seen (= flight ended), opens the
// damage buff window read by the skill's ModifyDamageGiven.
class ZTUpgrade_Skill_DesignatedHitter_Helper extends Actor;

var bool bMarkerSeen;
var float BuffEndTime;

const POLL_INTERVAL = 0.25f;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	SetTimer(POLL_INTERVAL, True, NameOf(PollMarker));
}

function PollMarker()
{
	local ZTFastball_PayloadMarker M;
	local bool bHasMarker;

	if (Owner == None)
	{
		Destroy();
		return;
	}

	foreach Owner.ChildActors(class'ZTFastball_PayloadMarker', M)
	{
		bHasMarker = True;
		break;
	}

	if (bHasMarker)
	{
		bMarkerSeen = True;
	}
	else if (bMarkerSeen)
	{
		// Flight just ended: open the buff window
		bMarkerSeen = False;
		BuffEndTime = WorldInfo.TimeSeconds + class'ZTUpgrade_Skill_DesignatedHitter'.default.BuffDuration;
	}
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None

	Name="Default__ZTUpgrade_Skill_DesignatedHitter_Helper"
}
