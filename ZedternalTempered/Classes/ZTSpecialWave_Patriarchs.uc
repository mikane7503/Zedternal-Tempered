// ===================================================================
// ZTSpecialWave_Patriarchs - Boss Rush: 10 Patriarchs
// ===================================================================
class ZTSpecialWave_Patriarchs extends WMSpecialWave;

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
		GameMutator.StartBossWave(class'ZedternalReborn.WMPawn_ZedPatriarch', 10);
		`log("ZTSpecialWave_Patriarchs: Started boss wave tracking");
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
	
	`log("ZTSpecialWave_Patriarchs: Spawned 10 Patriarchs in 2 groups");
}

function WaveEnded()
{
	`log("ZTSpecialWave_Patriarchs: Wave ended");
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
	
	Name="Default__ZTSpecialWave_Patriarchs"
}