// Tempered HUD wrapper with Zedternal Reborn's original scoreboard.
// Custom Ascension-style rank/title/stat columns have been rolled back.
class ZTGFxScoreBoardWrapper extends ZTHudWrapper;

var WMGFxHudScoreBoard ScoreBoard;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	ScoreBoard = spawn(class'ZedternalReborn.WMGFxHudScoreBoard');
	if (ScoreBoard != None)
		ScoreBoard.OverrideFontSize = class'ZedternalReborn.Config_LocalPreferences'.static.GetSBOverrideFontSize();
}

event PostRender()
{
	super.PostRender();
	if (bShowScores && ScoreBoard != None)
		ScoreBoard.Draw(Canvas);
}

exec function SetShowScores(bool show)
{
	super.SetShowScores(false);
	bShowScores = show;
}

defaultproperties
{
	Name="Default__ZTGFxScoreBoardWrapper"
}
