// ===================================================================
// ZTFastball_PayloadMarker - "This human is currently a projectile"
//
// Spawned on the LAUNCHED teammate's pawn for the duration of the
// flight. Two jobs:
//   1. Fall damage shield: both ZTGameInfos' ReduceDamage zero
//      falling damage for pawns carrying this marker.
//   2. Flight state for the launcher's helper poll: launcher ref
//      and peak fall speed for impact scaling.
// Self-destructs on a safety timeout in case the poll dies.
// ===================================================================
class ZTFastball_PayloadMarker extends Actor;

var KFPlayerController LauncherPC;
var int LauncherPerkLevel;
var float PeakSpeed;

const SAFETY_LIFETIME = 12.0f;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	SetTimer(SAFETY_LIFETIME, False, NameOf(SafetyExpire));
}

function SafetyExpire()
{
	Destroy();
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None

	Name="Default__ZTFastball_PayloadMarker"
}
