// ===================================================================
// DKSpecialWave_HansVolters - Boss Rush: 10 Hans Volters
// ===================================================================
class DKSpecialWave_HansVolters extends WMSpecialWave;

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
		GameMutator.StartBossWave(class'ZedternalReborn.WMPawn_ZedHans', 10);
		`log("DKSpecialWave_HansVolters: Started boss wave tracking");
	}
	
	SpawnBossGroups();
}

function SpawnBossGroups()
{
	local array< class<KFPawn_Monster> > BossGroup;
	local int i;
	
	// Group 1: 5 Hans at start
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedHans');
	}
	AddNewZedGroupToSpawnList(0, BossGroup, 5.0f);
	
	// Group 2: 5 Hans after short delay (spawns after first 5 are killed)
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedHans');
	}
	AddNewZedGroupToSpawnList(1, BossGroup, 10.0f);
	
	`log("DKSpecialWave_HansVolters: Spawned 10 Hans Volters in 2 groups");
}

function WaveEnded()
{
	`log("DKSpecialWave_HansVolters: Wave ended");
	super.WaveEnded();
}

defaultproperties
{
	Title="Onslaught: Hans Volter"
	Description="10 Hans Volters are coming for you!"
	bShouldLocalize=False
	
	ZedSpawnRateFactor=0.5f
	WaveValueFactor=2.0f
	DoshFactor=2.5f
	bReplaceMonstertoAdd=True
	
	Name="Default__DKSpecialWave_HansVolters"
}