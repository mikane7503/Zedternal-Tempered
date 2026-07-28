// ===================================================================
// DKSpecialWave_Matriarchs - Boss Rush: 10 Matriarchs
// ===================================================================
class DKSpecialWave_Matriarchs extends WMSpecialWave;

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
		GameMutator.StartBossWave(class'ZedternalReborn.WMPawn_ZedMatriarch', 10);
		`log("DKSpecialWave_Matriarchs: Started boss wave tracking");
	}
	
	SpawnBossGroups();
}

function SpawnBossGroups()
{
	local array< class<KFPawn_Monster> > BossGroup;
	local int i;
	
	// Group 1: 5 Matriarchs at start
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedMatriarch');
	}
	AddNewZedGroupToSpawnList(0, BossGroup, 5.0f);
	
	// Group 2: 5 Matriarchs after short delay (spawns after first 5 are killed)
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedMatriarch');
	}
	AddNewZedGroupToSpawnList(1, BossGroup, 10.0f);
	
	`log("DKSpecialWave_Matriarchs: Spawned 10 Matriarchs in 2 groups");
}

function WaveEnded()
{
	`log("DKSpecialWave_Matriarchs: Wave ended");
	super.WaveEnded();
}

defaultproperties
{
	Title="Onslaught: Matriarch"
	Description="Face the fury of 10 Matriarchs!"
	bShouldLocalize=False
	
	ZedSpawnRateFactor=0.5f
	WaveValueFactor=2.0f
	DoshFactor=2.5f
	bReplaceMonstertoAdd=True
	
	Name="Default__DKSpecialWave_Matriarchs"
}