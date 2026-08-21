// ===================================================================
// ZTSpecialWave_BloatKings - Boss Rush: 10 Bloat Kings
// ===================================================================
class ZTSpecialWave_BloatKings extends WMSpecialWave;

var ZTMutator GameMutator;

function PostBeginPlay()
{
	local ZTMutator DKM;
	
	super.PostBeginPlay();
	
	// Find the ZTMutator
	foreach WorldInfo.AllActors(class'ZTMutator', DKM)
	{
		GameMutator = DKM;
		break;
	}
	
	if (GameMutator != None)
	{
		// Notify mutator that boss wave started
		GameMutator.StartBossWave(class'ZedternalReborn.WMPawn_ZedBloatKing', 10);
		`log("ZTSpecialWave_BloatKings: Started boss wave tracking");
	}
	
	// Spawn the bosses in groups
	SpawnBossGroups();
}

function SpawnBossGroups()
{
	local array< class<KFPawn_Monster> > BossGroup;
	local int i;
	
	// Group 1: 5 Bloat Kings at start
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedBloatKing');
	}
	AddNewZedGroupToSpawnList(0, BossGroup, 5.0f);
	
	// Group 2: 5 Bloat Kings after short delay (spawns after first 5 are killed)
	BossGroup.Length = 0;
	for (i = 0; i < 5; i++)
	{
		BossGroup.AddItem(class'ZedternalReborn.WMPawn_ZedBloatKing');
	}
	AddNewZedGroupToSpawnList(1, BossGroup, 10.0f);
	
	`log("ZTSpecialWave_BloatKings: Spawned 10 Bloat Kings in 2 groups");
}

function WaveEnded()
{
	`log("ZTSpecialWave_BloatKings: Wave ended");
	super.WaveEnded();
}

defaultproperties
{
	Title="Onslaught: Bloat King"
	Description="Survive against 10 Bloat Kings!"
	bShouldLocalize=False
	
	// Reduce spawn rate for bosses
	ZedSpawnRateFactor=0.5f
	
	// Increase wave value for more dosh
	WaveValueFactor=2.0f
	DoshFactor=2.5f
	
	// Don't replace monster list, add to it
	bReplaceMonstertoAdd=True
	
	Name="Default__ZTSpecialWave_BloatKings"
}