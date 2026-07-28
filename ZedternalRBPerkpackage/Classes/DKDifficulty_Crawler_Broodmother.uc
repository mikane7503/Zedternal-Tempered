class DKDifficulty_Crawler_Broodmother extends KFDifficulty_CrawlerKing
	abstract;

defaultproperties
{
	// Normal difficulty
	Normal={(HealthMod=1.0,
		HeadHealthMod=1.0,
		EvadeOnDamageSettings=(Chance=0.0),
		RallySettings=(bCanRally=false)
	)}

	// Hard difficulty
	Hard={(DamageMod=1.0,
		HealthMod=1.1,
		EvadeOnDamageSettings=(Chance=0.0),
		RallySettings=(bCanRally=false)
	)}

	// Suicidal difficulty
	Suicidal={(SprintChance=0.85,
		DamagedSprintChance=1.0,
		DamageMod=1.1,
		HealthMod=1.2,
		MovementSpeedMod=1.1,
		EvadeOnDamageSettings=(Chance=0.0),
		RallySettings=(DealtDamageModifier=1.2, TakenDamageModifier=0.9)
	)}

	// Hell On Earth difficulty
	HellOnEarth={(SprintChance=1.0,
		DamagedSprintChance=1.0,
		DamageMod=1.2,
		HealthMod=1.3,
		MovementSpeedMod=1.15,
		EvadeOnDamageSettings=(Chance=0.0),
		RallySettings=(bCauseSprint=true, DealtDamageModifier=1.2, TakenDamageModifier=0.9)
	)}

	// No special crawler spawns from this
	ChanceToSpawnAsSpecial(`DIFFICULTY_Normal)=0.0
	ChanceToSpawnAsSpecial(`DIFFICULTY_Hard)=0.0
	ChanceToSpawnAsSpecial(`DIFFICULTY_Suicidal)=0.0
	ChanceToSpawnAsSpecial(`DIFFICULTY_HellOnEarth)=0.0

	Name="Default__DKDifficulty_Crawler_Broodmother"
}
