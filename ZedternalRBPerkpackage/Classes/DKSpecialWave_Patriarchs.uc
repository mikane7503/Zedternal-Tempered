// ===================================================================
// DKSpecialWave_Patriarchs - Boss Rush: 10 Patriarchs
// ===================================================================
class DKSpecialWave_Patriarchs extends WMSpecialWave;

var DKMutator GameMutator;

function PostBeginPlay()
{
	local DKMutator DKM;
	
	super.PostBeginPlay();
	
	foreach WorldInfo.AllActors(class'DKMutator', DKM)
	{
		GameMutator = DKM;
		break;
	}
	
	if (GameMutator != None)
	{
		GameMutator.StartBossWave(class'ZedternalReborn.WMPawn_ZedPatriarch', 10);
		`log("DKSpecialWave_Patriarchs: Started boss wave tracking");
	}
	
	SpawnBossGroups();
}

function SpawnBossGroups()
{
	local array< class<KFPawn_Monster> > BossGroup;
	local int i;
	
	// Group 1: 5 Patriarchs at start
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedPatriarch');
	}
	AddNewZedGroupToSpawnList(0, BossGroup, 5.0f);
	
	// Group 2: 5 Patriarchs after short delay (spawns after first 5 are killed)
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedPatriarch');
	}
	AddNewZedGroupToSpawnList(1, BossGroup, 10.0f);
	
	`log("DKSpecialWave_Patriarchs: Spawned 10 Patriarchs in 2 groups");
}

function WaveEnded()
{
	`log("DKSpecialWave_Patriarchs: Wave ended");
	super.WaveEnded();
}

defaultproperties
{
	Title="Onslaught: Patriarch"
	Description="10 Patriarchs want you dead!"
	bShouldLocalize=False
	
	ZedSpawnRateFactor=0.5f
	WaveValueFactor=2.0f
	DoshFactor=2.5f
	bReplaceMonstertoAdd=True
	
	Name="Default__DKSpecialWave_Patriarchs"
}