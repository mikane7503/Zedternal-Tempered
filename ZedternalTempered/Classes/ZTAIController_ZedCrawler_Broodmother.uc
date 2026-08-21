// ===================================================================
// ZTAIController_ZedCrawler_Broodmother
// Custom AI controller for the Broodmother crawler.
// When fleeing, prevents attacks and sprints away from players.
// ===================================================================
class ZTAIController_ZedCrawler_Broodmother extends KFAIController_ZedCrawlerKing;

var ZTPawn_ZedCrawler_Broodmother BroodPawn;

event Possess(Pawn inPawn, bool bVehicleTransition)
{
	super.Possess(inPawn, bVehicleTransition);
	BroodPawn = ZTPawn_ZedCrawler_Broodmother(inPawn);
}

function bool IsFleeing()
{
	return (BroodPawn != None && BroodPawn.bFleeing);
}

// Force sprinting when fleeing
function bool ShouldSprint()
{
	if (IsFleeing())
		return true;

	return super.ShouldSprint();
}

// Clear enemy periodically via timer called from the pawn
function ClearEnemyForFlee()
{
	if (Enemy != None)
		Enemy = None;
}

defaultproperties
{
	bAllowScriptTeamCheck=True

	Name="Default__ZTAIController_ZedCrawler_Broodmother"
}
