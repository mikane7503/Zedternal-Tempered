class DKGameDifficulty_Endless extends WMGameDifficulty_Endless;

function float GetAISpeedMod(KFPawn_Monster P, float GameDifficulty)
{
	local float SpeedMod;
	local DKGameReplicationInfo DKGRI;

	SpeedMod = Super.GetAISpeedMod(P, GameDifficulty);

	DKGRI = DKGameReplicationInfo(Class'WorldInfo'.static.GetWorldInfo().GRI);
	if (DKGRI != None && DKGRI.ActiveEventWaveID == 13)
	{
		SpeedMod *= 2.0;
	}

	return SpeedMod;
}

defaultproperties
{
	Name="Default__DKGameDifficulty_Endless"
}
