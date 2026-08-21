// ===================================================================
// ZTUpgrade_Skill_Contagion_Helper
// Periodically checks all siphoned enemies and spreads siphon to
// nearby non-siphoned enemies. Creates an infection-like spread
// pattern through densely packed hordes.
// ===================================================================
class ZTUpgrade_Skill_Contagion_Helper extends Info transient;

var KFPawn_Human Player;

// Config (set by skill on spawn)
var float SpreadRadius;
var float SpreadInterval;

function PostBeginPlay()
{
	super.PostBeginPlay();

	Player = KFPawn_Human(Owner);
	if (Player == None || Player.Health <= 0)
		Destroy();
}

function StartSpreadTimer()
{
	SetTimer(SpreadInterval, True, NameOf(CheckContagionSpread));
}

function CheckContagionSpread()
{
	local ZTUpgrade_Perk_Parasite_Helper ParasiteHelper;
	local array<KFPawn_Monster> SiphonedList;
	local KFPawn_Monster KFPM;
	local float RadiusSq;
	local int i;

	if (Player == None || Player.Health <= 0)
	{
		Destroy();
		return;
	}

	// Find Parasite helper
	foreach Player.ChildActors(class'ZTUpgrade_Perk_Parasite_Helper', ParasiteHelper)
		break;

	if (ParasiteHelper == None)
		return;

	// Get current siphoned enemies
	ParasiteHelper.GetSiphonedEnemies(SiphonedList);
	if (SiphonedList.Length == 0)
		return;

	RadiusSq = SpreadRadius ** 2;
	// For each siphoned enemy, check for nearby non-siphoned enemies
	for (i = 0; i < SiphonedList.Length; ++i)
	{
		if (SiphonedList[i] == None || SiphonedList[i].Health <= 0)
			continue;

		// Check if we're at max siphons already
		if (ParasiteHelper.GetSiphonedEnemyCount() >= ParasiteHelper.GetMaxSiphons())
			break;

		foreach Player.WorldInfo.AllPawns(class'KFPawn_Monster', KFPM)
		{
			if (KFPM.Health <= 0 || !KFPM.IsAliveAndWell())
				continue;

			// Skip already siphoned
			if (ParasiteHelper.IsSiphoned(KFPM))
				continue;

			// Check proximity to THIS siphoned enemy
			if (VSizeSq(KFPM.Location - SiphonedList[i].Location) <= RadiusSq)
			{
				ParasiteHelper.ApplySiphonToTarget(KFPM);

				// Only spread to one new target per siphoned enemy per tick
				// to prevent instant full-horde infection
				break;
			}
		}

		// Re-check cap after each spread
		if (ParasiteHelper.GetSiphonedEnemyCount() >= ParasiteHelper.GetMaxSiphons())
			break;
	}
}

defaultproperties
{
	bOnlyRelevantToOwner=True

	Name="Default__ZTUpgrade_Skill_Contagion_Helper"
}
