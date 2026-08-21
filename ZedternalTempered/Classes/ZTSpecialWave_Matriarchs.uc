// ===================================================================
// ZTSpecialWave_Matriarchs - Boss Rush: 10 Matriarchs
// ===================================================================
class ZTSpecialWave_Matriarchs extends WMSpecialWave;

var ZTMutator GameMutator;

function PostBeginPlay()
{
	local ZTMutator DKM;
	
	super.PostBeginPlay();
	
	foreach WorldInfo.AllActors(class'ZTMutator', DKM)
	{
		GameMutator = DKM;
		break;
	}
	
	if (GameMutator != None)
	{
		GameMutator.StartBossWave(class'ZedternalReborn.WMPawn_ZedMatriarch', 10);
		`log("ZTSpecialWave_Matriarchs: Started boss wave tracking");
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
	
	`log("ZTSpecialWave_Matriarchs: Spawned 10 Matriarchs in 2 groups");
}

function WaveEnded()
{
	`log("ZTSpecialWave_Matriarchs: Wave ended");
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
	
	Name="Default__ZTSpecialWave_Matriarchs"
}