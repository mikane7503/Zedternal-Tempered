// ===================================================================
// DKGFxScoreBoardWrapper - Wrapper that manages the custom scoreboard
// Extends DKHudWrapper to inherit all perk tracking and notification systems
//
// DKScoreboard extends WMGFxHudScoreBoard (an Actor), so we spawn() it.
// ScoreBoard var is declared here since DKHudWrapper doesn't have it
// (we don't extend WMGFxScoreBoardWrapper).
// ===================================================================
class DKGFxScoreBoardWrapper extends DKHudWrapper;

var DKScoreboard ScoreBoard;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	ScoreBoard = spawn(class'DKScoreboard');

	if (ScoreBoard != None)
		`log("DKGFxScoreBoardWrapper: Scoreboard spawned successfully");
	else
		`log("DKGFxScoreBoardWrapper: CRITICAL ERROR - Failed to spawn scoreboard");
}

event PostRender()
{
	super.PostRender();

	if (bShowScores)
	{
		if (ScoreBoard != None)
			ScoreBoard.Draw(Canvas);
	}
}

// Override to prevent showing default Scaleform scoreboard
exec function SetShowScores(bool show)
{
	super.SetShowScores(false); // Always prevent default scoreboard
	bShowScores = show;         // Set our own flag for custom scoreboard
}

// Debug command
exec function DebugScoreboardWrapper()
{
	if (PlayerOwner != None)
	{
		PlayerOwner.ClientMessage("=== DKGFxScoreBoardWrapper Debug ===");
		if (ScoreBoard != None)
			PlayerOwner.ClientMessage("ScoreBoard: OK");
		else
			PlayerOwner.ClientMessage("ScoreBoard: NONE");
		PlayerOwner.ClientMessage("bShowScores:" @ bShowScores);
	}
}

defaultproperties
{
	Name="Default__DKGFxScoreBoardWrapper"
}
