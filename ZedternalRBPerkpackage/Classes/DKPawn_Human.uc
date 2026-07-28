// ===================================================================
// DKPawn_Human - Extends WMPawn_Human
// Adds configurable speed modifier and speed cap support.
// Values are replicated so client prediction stays in sync.
// ===================================================================
class DKPawn_Human extends WMPawn_Human;

// Replicated speed config values (server reads from DKConfig_PlayerSpeed)
var float DKSpeedModifier;
var float DKSpeedCap;

replication
{
	if (bNetDirty)
		DKSpeedModifier, DKSpeedCap;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// Server: load config values and replicate to clients
	if (Role == ROLE_Authority)
	{
		DKSpeedModifier = class'DKConfig_PlayerSpeed'.default.Player_SpeedModifier;
		DKSpeedCap = class'DKConfig_PlayerSpeed'.default.Player_SpeedCap;
	}
}

// Override UpdateGroundSpeed to apply global speed modifier and cap
// after all perk/skill/equipment bonuses have been calculated by super.
simulated event UpdateGroundSpeed()
{
	local float SprintRatio;

	// Let WM/KF2 do all standard speed calculations
	Super.UpdateGroundSpeed();

	// Apply global speed modifier (0.0 = disabled)
	if (DKSpeedModifier > 0.0f)
	{
		GroundSpeed *= DKSpeedModifier;
		SprintSpeed *= DKSpeedModifier;
	}

	// Apply speed cap (0.0 = disabled)
	if (DKSpeedCap > 0.0f && GroundSpeed > DKSpeedCap)
	{
		// Preserve the sprint-to-ground ratio when capping
		if (GroundSpeed > 0.0f)
			SprintRatio = SprintSpeed / GroundSpeed;
		else
			SprintRatio = 1.2f;

		GroundSpeed = DKSpeedCap;
		SprintSpeed = DKSpeedCap * SprintRatio;
	}
}

defaultproperties
{
	DKSpeedModifier=0.0f
	DKSpeedCap=0.0f
}
