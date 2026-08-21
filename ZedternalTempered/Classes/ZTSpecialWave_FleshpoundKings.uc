// ===================================================================
// ZTSpecialWave_FleshpoundKings - Boss Rush: 10 Fleshpound Kings
// ===================================================================
class ZTSpecialWave_FleshpoundKings extends WMSpecialWave;

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
		GameMutator.StartBossWave(class'ZedternalReborn.WMPawn_ZedFleshpoundKing', 10);
		`log("ZTSpecialWave_FleshpoundKings: Started boss wave tracking");
	}
	
	SpawnBossGroups();
}

function SpawnBossGroups()
{
	local array< class<KFPawn_Monster> > BossGroup;
	local int i;
	
	// Group 1: 5 Fleshpound Kings at start
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedFleshpoundKing');
	}
	AddNewZedGroupToSpawnList(0, BossGroup, 5.0f);
	
	// Group 2: 5 Fleshpound Kings after short delay (spawns after first 5 are killed)
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedFleshpoundKing');
	}
	AddNewZedGroupToSpawnList(1, BossGroup, 10.0f);
	
	`log("ZTSpecialWave_FleshpoundKings: Spawned 10 Fleshpound Kings in 2 groups");
}

function WaveEnded()
{
	`log("ZTSpecialWave_FleshpoundKings: Wave ended");
	super.WaveEnded();
}

defaultproperties
{
	Title="Onslaught: Fleshpound King"
	Description="Survive the wrath of 10 Fleshpound Kings!"
	bShouldLocalize=False
	
	ZedSpawnRateFactor=0.5f
	WaveValueFactor=2.0f
	DoshFactor=2.5f
	bReplaceMonstertoAdd=True
	
	Name="Default__ZTSpecialWave_FleshpoundKings"
}