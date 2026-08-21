class Config_Player extends Config_Common
	config(ZedternalReborn_Game);

var config int MODEVERSION;

var config S_Difficulty_Bool Player_bDropAllWeaponsWhenDead;
var config S_Difficulty_Int Player_StartingWeaponAmount;
var config S_Difficulty_Int Player_StartingMaxHealth;
var config S_Difficulty_Int Player_StartingMaxArmor;
var config S_Difficulty_Int Player_StartingCarryWeight;
var config S_Difficulty_Int Player_StartingMaxGrenadeCount;
var config S_Difficulty_Float Player_HealAmountMultiplier;
var config S_Difficulty_Float Player_DamageTakenMultiplierWhileHoldingMelee;

struct S_Damage
{
	var string DamageType;
	var float Multiplier;
};
var config array<S_Damage> Player_DamageGiven;
var config array<S_Damage> Player_DamageTaken;

struct S_Vampire
{
	var string DamageType;
	var int HealAmount;
};
var config array<S_Vampire> Player_VampireEffect;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Player_bDropAllWeaponsWhenDead.Normal = True;
		default.Player_bDropAllWeaponsWhenDead.Hard = True;
		default.Player_bDropAllWeaponsWhenDead.Suicidal = True;
		default.Player_bDropAllWeaponsWhenDead.HoE = True;
		default.Player_bDropAllWeaponsWhenDead.Custom = True;

		default.Player_StartingWeaponAmount.Normal = 1;
		default.Player_StartingWeaponAmount.Hard = 1;
		default.Player_StartingWeaponAmount.Suicidal = 1;
		default.Player_StartingWeaponAmount.HoE = 1;
		default.Player_StartingWeaponAmount.Custom = 1;

		default.Player_StartingMaxHealth.Normal = 100;
		default.Player_StartingMaxHealth.Hard = 100;
		default.Player_StartingMaxHealth.Suicidal = 100;
		default.Player_StartingMaxHealth.HoE = 100;
		default.Player_StartingMaxHealth.Custom = 100;

		default.Player_StartingMaxArmor.Normal = 100;
		default.Player_StartingMaxArmor.Hard = 100;
		default.Player_StartingMaxArmor.Suicidal = 100;
		default.Player_StartingMaxArmor.HoE = 100;
		default.Player_StartingMaxArmor.Custom = 100;

		default.Player_StartingCarryWeight.Normal = 15;
		default.Player_StartingCarryWeight.Hard = 15;
		default.Player_StartingCarryWeight.Suicidal = 15;
		default.Player_StartingCarryWeight.HoE = 15;
		default.Player_StartingCarryWeight.Custom = 15;

		default.Player_HealAmountMultiplier.Normal = 1.0f;
		default.Player_HealAmountMultiplier.Hard = 1.0f;
		default.Player_HealAmountMultiplier.Suicidal = 1.0f;
		default.Player_HealAmountMultiplier.HoE = 1.0f;
		default.Player_HealAmountMultiplier.Custom = 1.0f;

		default.Player_DamageTakenMultiplierWhileHoldingMelee.Normal = 0.9f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.Hard = 0.9f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.Suicidal = 0.9f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.HoE = 0.9f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.Custom = 0.9f;

		default.Player_DamageGiven.Length = 6;
		default.Player_DamageGiven[0].DamageType = "KFGame.KFDT_Bludgeon";
		default.Player_DamageGiven[0].Multiplier = 1.15f;
		default.Player_DamageGiven[1].DamageType = "KFGame.KFDT_Piercing";
		default.Player_DamageGiven[1].Multiplier = 1.15f;
		default.Player_DamageGiven[2].DamageType = "KFGame.KFDT_Slashing";
		default.Player_DamageGiven[2].Multiplier = 1.15f;
		default.Player_DamageGiven[3].DamageType = "KFGame.KFDT_Fire";
		default.Player_DamageGiven[3].Multiplier = 1.1f;
		default.Player_DamageGiven[4].DamageType = "KFGameContent.KFDT_Freeze_FreezeThrower";
		default.Player_DamageGiven[4].Multiplier = 1.15f;
		default.Player_DamageGiven[5].DamageType = "KFGame.KFDT_Toxic_MedicGrenade";
		default.Player_DamageGiven[5].Multiplier = 0.8f;

		default.Player_DamageTaken.Length = 6;
		default.Player_DamageTaken[0].DamageType = "KFGame.KFDT_Fire";
		default.Player_DamageTaken[0].Multiplier = 0.9f;
		default.Player_DamageTaken[1].DamageType = "KFGameContent.KFDT_Explosive_HuskSuicide";
		default.Player_DamageTaken[1].Multiplier = 0.75f;
		default.Player_DamageTaken[2].DamageType = "KFGameContent.KFDT_FleshpoundKing_ChestBeam";
		default.Player_DamageTaken[2].Multiplier = 0.75f;
		default.Player_DamageTaken[3].DamageType = "KFGameContent.KFDT_Explosive_HansHEGrenade";
		default.Player_DamageTaken[3].Multiplier = 0.75f;
		default.Player_DamageTaken[4].DamageType = "KFGameContent.KFDT_Explosive_PatMissile";
		default.Player_DamageTaken[4].Multiplier = 0.75f;
		default.Player_DamageTaken[5].DamageType = "KFGameContent.KFDT_EMP_MatriarchPlasmaCannon";
		default.Player_DamageTaken[5].Multiplier = 0.75f;

		default.Player_VampireEffect.Length = 3;
		default.Player_VampireEffect[0].DamageType = "KFGame.KFDT_Bludgeon";
		default.Player_VampireEffect[0].HealAmount = 3;
		default.Player_VampireEffect[1].DamageType = "KFGame.KFDT_Piercing";
		default.Player_VampireEffect[1].HealAmount = 3;
		default.Player_VampireEffect[2].DamageType = "KFGame.KFDT_Slashing";
		default.Player_VampireEffect[2].HealAmount = 3;
	}

	if (default.MODEVERSION < 18)
	{
		default.Player_StartingMaxGrenadeCount.Normal = 5;
		default.Player_StartingMaxGrenadeCount.Hard = 5;
		default.Player_StartingMaxGrenadeCount.Suicidal = 5;
		default.Player_StartingMaxGrenadeCount.HoE = 5;
		default.Player_StartingMaxGrenadeCount.Custom = 5;
	}

	if (default.MODEVERSION < class'ZedternalReborn.Config_Base'.const.CurrentVersion)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Player_StartingWeaponAmount.Normal = 1;
		default.Player_StartingWeaponAmount.Hard = 1;
		default.Player_StartingWeaponAmount.Suicidal = 1;
		default.Player_StartingWeaponAmount.HOE = 1;
		default.Player_StartingWeaponAmount.Custom = 1;
		default.Player_StartingMaxHealth.Normal = 100;
		default.Player_StartingMaxHealth.Hard = 100;
		default.Player_StartingMaxHealth.Suicidal = 100;
		default.Player_StartingMaxHealth.HOE = 100;
		default.Player_StartingMaxHealth.Custom = 100;
		default.Player_StartingMaxArmor.Normal = 100;
		default.Player_StartingMaxArmor.Hard = 100;
		default.Player_StartingMaxArmor.Suicidal = 100;
		default.Player_StartingMaxArmor.HOE = 100;
		default.Player_StartingMaxArmor.Custom = 100;
		default.Player_StartingCarryWeight.Normal = 15;
		default.Player_StartingCarryWeight.Hard = 15;
		default.Player_StartingCarryWeight.Suicidal = 15;
		default.Player_StartingCarryWeight.HOE = 15;
		default.Player_StartingCarryWeight.Custom = 15;
		default.Player_StartingMaxGrenadeCount.Normal = 5;
		default.Player_StartingMaxGrenadeCount.Hard = 5;
		default.Player_StartingMaxGrenadeCount.Suicidal = 5;
		default.Player_StartingMaxGrenadeCount.HOE = 5;
		default.Player_StartingMaxGrenadeCount.Custom = 5;
		default.Player_HealAmountMultiplier.Normal = 1.0f;
		default.Player_HealAmountMultiplier.Hard = 1.0f;
		default.Player_HealAmountMultiplier.Suicidal = 1.0f;
		default.Player_HealAmountMultiplier.HOE = 1.0f;
		default.Player_HealAmountMultiplier.Custom = 1.0f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.Normal = 0.750000f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.Hard = 0.750000f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.Suicidal = 0.750000f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.HOE = 0.750000f;
		default.Player_DamageTakenMultiplierWhileHoldingMelee.Custom = 0.750000f;
		default.Player_DamageGiven.Length = 48;
		default.Player_DamageGiven[0].DamageType = "KFGame.KFDT_Fire";
		default.Player_DamageGiven[0].Multiplier = 0.500000f;
		default.Player_DamageGiven[1].DamageType = "KFGame.KFDT_Fire_Ground";
		default.Player_DamageGiven[1].Multiplier = 0.400000f;
		default.Player_DamageGiven[2].DamageType = "KFGame.KFDT_Fire_Napalm";
		default.Player_DamageGiven[2].Multiplier = 0.400000f;
		default.Player_DamageGiven[3].DamageType = "KFGame.KFDT_Explosive";
		default.Player_DamageGiven[3].Multiplier = 0.400000f;
		default.Player_DamageGiven[4].DamageType = "KFGame.KFDT_Explosive_Shrapnel";
		default.Player_DamageGiven[4].Multiplier = 0.500000f;
		default.Player_DamageGiven[5].DamageType = "KFGame.KFDT_Toxic_MedicGrenade";
		default.Player_DamageGiven[5].Multiplier = 0.250000f;
		default.Player_DamageGiven[6].DamageType = "KFGame.KFDT_Slashing";
		default.Player_DamageGiven[6].Multiplier = 0.850000f;
		default.Player_DamageGiven[7].DamageType = "KFGame.KFDT_Piercing";
		default.Player_DamageGiven[7].Multiplier = 0.850000f;
		default.Player_DamageGiven[8].DamageType = "KFGame.KFDT_Bludgeon";
		default.Player_DamageGiven[8].Multiplier = 0.850000f;
		default.Player_DamageGiven[9].DamageType = "KFGameContent.KFDT_Ballistic_Shotgun";
		default.Player_DamageGiven[9].Multiplier = 0.600000f;
		default.Player_DamageGiven[10].DamageType = "KFGameContent.KFDT_Freeze_FreezeThrower";
		default.Player_DamageGiven[10].Multiplier = 1.250000f;
		default.Player_DamageGiven[11].DamageType = "KFGameContent.KFDT_Freeze_FreezeThrower_IceShards";
		default.Player_DamageGiven[11].Multiplier = 1.750000f;
		default.Player_DamageGiven[12].DamageType = "KFGameContent.KFDT_Ballistic_CenterfireMB464";
		default.Player_DamageGiven[12].Multiplier = 0.750000f;
		default.Player_DamageGiven[13].DamageType = "KFGameContent.KFDT_Ballistic_Winchester";
		default.Player_DamageGiven[13].Multiplier = 0.750000f;
		default.Player_DamageGiven[14].DamageType = "KFGameContent.KFDT_Ballistic_SW500";
		default.Player_DamageGiven[14].Multiplier = 0.800000f;
		default.Player_DamageGiven[15].DamageType = "KFGameContent.KFDT_Ballistic_M99";
		default.Player_DamageGiven[15].Multiplier = 0.850000f;
		default.Player_DamageGiven[16].DamageType = "KFGameContent.KFDT_Ballistic_RailGun";
		default.Player_DamageGiven[16].Multiplier = 0.900000f;
		default.Player_DamageGiven[17].DamageType = "KFGameContent.KFDT_Explosive_HuskCannon";
		default.Player_DamageGiven[17].Multiplier = 0.800000f;
		default.Player_DamageGiven[18].DamageType = "KFGameContent.KFDT_Ballistic_RPG7Impact";
		default.Player_DamageGiven[18].Multiplier = 1.500000f;
		default.Player_DamageGiven[19].DamageType = "KFGameContent.KFDT_Explosive_RPG7BackBlast";
		default.Player_DamageGiven[19].Multiplier = 10.000000f;
		default.Player_DamageGiven[20].DamageType = "KFGameContent.KFDT_Explosive_Pulverizer";
		default.Player_DamageGiven[20].Multiplier = 2.500000f;
		default.Player_DamageGiven[21].DamageType = "KFGameContent.KFDT_EMP_HVStormCannon";
		default.Player_DamageGiven[21].Multiplier = 0.850000f;
		default.Player_DamageGiven[22].DamageType = "KFGameContent.KFDT_Explosive_HRG_Kaboomstick";
		default.Player_DamageGiven[22].Multiplier = 0.850000f;
		default.Player_DamageGiven[23].DamageType = "KFGameContent.KFDT_Piercing_Crossbow";
		default.Player_DamageGiven[23].Multiplier = 1.300000f;
		default.Player_DamageGiven[24].DamageType = "KFGameContent.KFDT_Piercing_CompoundBowSharpImpact";
		default.Player_DamageGiven[24].Multiplier = 1.500000f;
		default.Player_DamageGiven[25].DamageType = "KFGameContent.KFDT_Ballistic_M14EBR";
		default.Player_DamageGiven[25].Multiplier = 1.300000f;
		default.Player_DamageGiven[26].DamageType = "KFGameContent.KFDT_Ballistic_FNFal";
		default.Player_DamageGiven[26].Multiplier = 1.200000f;
		default.Player_DamageGiven[27].DamageType = "KFGameContent.KFDT_Ballistic_MG3";
		default.Player_DamageGiven[27].Multiplier = 1.100000f;
		default.Player_DamageGiven[28].DamageType = "KFGameContent.KFDT_Ballistic_MG3_Alt";
		default.Player_DamageGiven[28].Multiplier = 1.100000f;
		default.Player_DamageGiven[29].DamageType = "KFGameContent.KFDT_Ballistic_Stoner63A";
		default.Player_DamageGiven[29].Multiplier = 1.100000f;
		default.Player_DamageGiven[30].DamageType = "KFGameContent.KFDT_Ballistic_Minigun";
		default.Player_DamageGiven[30].Multiplier = 1.100000f;
		default.Player_DamageGiven[31].DamageType = "KFGameContent.KFDT_Ballistic_MKB42";
		default.Player_DamageGiven[31].Multiplier = 1.200000f;
		default.Player_DamageGiven[32].DamageType = "KFGameContent.KFDT_Ballistic_MosinNagant";
		default.Player_DamageGiven[32].Multiplier = 1.100000f;
		default.Player_DamageGiven[33].DamageType = "KFGameContent.KFDT_Piercing_MosinNagant";
		default.Player_DamageGiven[33].Multiplier = 1.400000f;
		default.Player_DamageGiven[34].DamageType = "KFGameContent.KFDT_Ballistic_Minigun";
		default.Player_DamageGiven[34].Multiplier = 1.100000f;
		default.Player_DamageGiven[35].DamageType = "KFGameContent.KFDT_Bludgeon_HRG_BallisticBouncer_Shot";
		default.Player_DamageGiven[35].Multiplier = 0.600000f;
		default.Player_DamageGiven[36].DamageType = "KFGameContent.KFDT_Ballistic_M4Shotgun";
		default.Player_DamageGiven[36].Multiplier = 1.200000f;
		default.Player_DamageGiven[37].DamageType = "KFGameContent.KFDT_Ballistic_NailShotgun";
		default.Player_DamageGiven[37].Multiplier = 1.300000f;
		default.Player_DamageGiven[38].DamageType = "KFGameContent.KFDT_Ballistic_ParasiteImplanter";
		default.Player_DamageGiven[38].Multiplier = 1.200000f;
		default.Player_DamageGiven[39].DamageType = "KFGameContent.KFDT_Explosive_C4";
		default.Player_DamageGiven[39].Multiplier = 2.000000f;
		default.Player_DamageGiven[40].DamageType = "KFGameContent.KFDT_Explosive_SealSqueal";
		default.Player_DamageGiven[40].Multiplier = 1.300000f;
		default.Player_DamageGiven[41].DamageType = "KFGameContent.KFDT_Ballistic_SealSquealImpact";
		default.Player_DamageGiven[41].Multiplier = 2.000000f;
		default.Player_DamageGiven[42].DamageType = "KFGameContent.KFDT_Explosive_GravityImploder";
		default.Player_DamageGiven[42].Multiplier = 1.300000f;
		default.Player_DamageGiven[43].DamageType = "KFGameContent.KFDT_Ballistic_GravityImploderImpactAlt";
		default.Player_DamageGiven[43].Multiplier = 3.000000f;
		default.Player_DamageGiven[44].DamageType = "KFGameContent.KFDT_Ballistic_MicrowaveRifle";
		default.Player_DamageGiven[44].Multiplier = 1.400000f;
		default.Player_DamageGiven[45].DamageType = "KFGameContent.KFDT_Ballistic_G18";
		default.Player_DamageGiven[45].Multiplier = 1.250000f;
		default.Player_DamageGiven[46].DamageType = "KFGameContent.KFDT_Bludgeon_G18Shield";
		default.Player_DamageGiven[46].Multiplier = 4.000000f;
		default.Player_DamageGiven[47].DamageType = "KFGameContent.KFDT_Bludgeon_G18Shield_Impulse";
		default.Player_DamageGiven[47].Multiplier = 4.000000f;
		default.Player_DamageTaken.Length = 9;
		default.Player_DamageTaken[0].DamageType = "KFGameContent.KFDT_Explosive_HuskSuicide";
		default.Player_DamageTaken[0].Multiplier = 1.300000f;
		default.Player_DamageTaken[1].DamageType = "KFGameContent.KFDT_FleshpoundKing_ChestBeam";
		default.Player_DamageTaken[1].Multiplier = 0.750000f;
		default.Player_DamageTaken[2].DamageType = "KFGameContent.KFDT_Explosive_HansHEGrenade";
		default.Player_DamageTaken[2].Multiplier = 0.750000f;
		default.Player_DamageTaken[3].DamageType = "KFGameContent.KFDT_Explosive_PatMissile";
		default.Player_DamageTaken[3].Multiplier = 0.750000f;
		default.Player_DamageTaken[4].DamageType = "KFGameContent.KFDT_EMP_MatriarchPlasmaCannon";
		default.Player_DamageTaken[4].Multiplier = 0.600000f;
		default.Player_DamageTaken[5].DamageType = "KFGameContent.KFDT_Sonic";
		default.Player_DamageTaken[5].Multiplier = 1.500000f;
		default.Player_DamageTaken[6].DamageType = "KFGameContent.KFDT_Toxic";
		default.Player_DamageTaken[6].Multiplier = 2.000000f;
		default.Player_DamageTaken[7].DamageType = "KFGameContent.KFDT_Fire_HuskFireball";
		default.Player_DamageTaken[7].Multiplier = 1.250000f;
		default.Player_DamageTaken[8].DamageType = "KFGameContent.KFDT_Fire_HuskFlamethrower";
		default.Player_DamageTaken[8].Multiplier = 1.500000f;
		default.Player_VampireEffect.Length = 3;
		default.Player_VampireEffect[0].DamageType = "KFGame.KFDT_Bludgeon";
		default.Player_VampireEffect[0].HealAmount = 3;
		default.Player_VampireEffect[1].DamageType = "KFGame.KFDT_Piercing";
		default.Player_VampireEffect[1].HealAmount = 3;
		default.Player_VampireEffect[2].DamageType = "KFGame.KFDT_Slashing";
		default.Player_VampireEffect[2].HealAmount = 3;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i;

	for (i = 0; i < NumberOfDiffs; ++i)
	{
		if (GetStructValueInt(default.Player_StartingWeaponAmount, i) < 0)
		{
			LogBadStructConfigMessage(i, "Player_StartingWeaponAmount",
				string(GetStructValueInt(default.Player_StartingWeaponAmount, i)),
				"0", "0 weapons, no starting weapons", "value >= 0");
			SetStructValueInt(default.Player_StartingWeaponAmount, i, 0);
		}

		if (GetStructValueInt(default.Player_StartingMaxHealth, i) < 1)
		{
			LogBadStructConfigMessage(i, "Player_StartingMaxHealth",
				string(GetStructValueInt(default.Player_StartingMaxHealth, i)),
				"1", "1 max health", "value >= 1");
			SetStructValueInt(default.Player_StartingMaxHealth, i, 1);
		}

		if (GetStructValueInt(default.Player_StartingMaxArmor, i) < 1)
		{
			LogBadStructConfigMessage(i, "Player_StartingMaxArmor",
				string(GetStructValueInt(default.Player_StartingMaxArmor, i)),
				"1", "1 max armor", "value >= 1");
			SetStructValueInt(default.Player_StartingMaxArmor, i, 1);
		}

		if (GetStructValueInt(default.Player_StartingCarryWeight, i) < 1)
		{
			LogBadStructConfigMessage(i, "Player_StartingCarryWeight",
				string(GetStructValueInt(default.Player_StartingCarryWeight, i)),
				"1", "1 carry weight", "value >= 1");
			SetStructValueInt(default.Player_StartingCarryWeight, i, 1);
		}

		if (GetStructValueInt(default.Player_StartingMaxGrenadeCount, i) < 0)
		{
			LogBadStructConfigMessage(i, "Player_StartingMaxGrenadeCount",
				string(GetStructValueInt(default.Player_StartingMaxGrenadeCount, i)),
				"0", "0 grenades, no starting grenade capacity", "value >= 0");
			SetStructValueInt(default.Player_StartingMaxGrenadeCount, i, 0);
		}

		if (GetStructValueFloat(default.Player_HealAmountMultiplier, i) < 0.0f)
		{
			LogBadStructConfigMessage(i, "Player_HealAmountMultiplier",
				string(GetStructValueFloat(default.Player_HealAmountMultiplier, i)),
				"0.0", "0%, no healing", "value >= 0.0");
			SetStructValueFloat(default.Player_HealAmountMultiplier, i, 0.0f);
		}

		if (GetStructValueFloat(default.Player_DamageTakenMultiplierWhileHoldingMelee, i) < 0.0f)
		{
			LogBadStructConfigMessage(i, "Player_DamageTakenMultiplierWhileHoldingMelee",
				string(GetStructValueFloat(default.Player_DamageTakenMultiplierWhileHoldingMelee, i)),
				"0.0", "0%, no damage taken", "value >= 0.0");
			SetStructValueFloat(default.Player_DamageTakenMultiplierWhileHoldingMelee, i, 0.0f);
		}
	}

	for (i = 0; i < default.Player_DamageGiven.Length; ++i)
	{
		if (default.Player_DamageGiven[i].Multiplier < 0.0f)
		{
			LogBadConfigMessage("Player_DamageGiven - Line" @ string(i + 1) @ "- Multiplier",
				string(default.Player_DamageGiven[i].Multiplier),
				"0.0", "0%, no damage given", "value >= 0.0");
			default.Player_DamageGiven[i].Multiplier = 0.0f;
		}
	}

	for (i = 0; i < default.Player_DamageTaken.Length; ++i)
	{
		if (default.Player_DamageTaken[i].Multiplier < 0.0f)
		{
			LogBadConfigMessage("Player_DamageTaken - Line" @ string(i + 1) @ "- Multiplier",
				string(default.Player_DamageTaken[i].Multiplier),
				"0.0", "0%, no damage taken", "value >= 0.0");
			default.Player_DamageTaken[i].Multiplier = 0.0f;
		}
	}

	for (i = 0; i < default.Player_VampireEffect.Length; ++i)
	{
		if (default.Player_VampireEffect[i].HealAmount < 0)
		{
			LogBadConfigMessage("Player_VampireEffect - Line" @ string(i + 1) @ "- HealAmount",
				string(default.Player_VampireEffect[i].HealAmount),
				"0", "0 points, no healing", "value >= 0");
			default.Player_VampireEffect[i].HealAmount = 0;
		}
	}
}

static function LoadConfigObjects_DamageGiven(out array<S_Damage> ValidDT, out array< class<DamageType> > DTObjects)
{
	local int i;
	local class<DamageType> Obj;

	ValidDT.Length = 0;
	DTObjects.Length = 0;

	for (i = 0; i < default.Player_DamageGiven.Length; ++i)
	{
		Obj = class<DamageType>(DynamicLoadObject(default.Player_DamageGiven[i].DamageType, class'Class', True));
		if (Obj == None)
		{
			LogBadLoadObjectConfigMessage("Player_DamageGiven", i + 1, default.Player_DamageGiven[i].DamageType);
		}
		else
		{
			ValidDT.AddItem(default.Player_DamageGiven[i]);
			DTObjects.AddItem(Obj);
		}
	}
}

static function LoadConfigObjects_DamageTaken(out array<S_Damage> ValidDT, out array< class<DamageType> > DTObjects)
{
	local int i;
	local class<DamageType> Obj;

	ValidDT.Length = 0;
	DTObjects.Length = 0;

	for (i = 0; i < default.Player_DamageTaken.Length; ++i)
	{
		Obj = class<DamageType>(DynamicLoadObject(default.Player_DamageTaken[i].DamageType, class'Class', True));
		if (Obj == None)
		{
			LogBadLoadObjectConfigMessage("Player_DamageTaken", i + 1, default.Player_DamageTaken[i].DamageType);
		}
		else
		{
			ValidDT.AddItem(default.Player_DamageTaken[i]);
			DTObjects.AddItem(Obj);
		}
	}
}

static function LoadConfigObjects_Vampire(out array<S_Vampire> ValidDT, out array< class<DamageType> > DTObjects)
{
	local int i;
	local class<DamageType> Obj;

	ValidDT.Length = 0;
	DTObjects.Length = 0;

	for (i = 0; i < default.Player_VampireEffect.Length; ++i)
	{
		Obj = class<DamageType>(DynamicLoadObject(default.Player_VampireEffect[i].DamageType, class'Class', True));
		if (Obj == None)
		{
			LogBadLoadObjectConfigMessage("Player_VampireEffect", i + 1, default.Player_VampireEffect[i].DamageType);
		}
		else
		{
			ValidDT.AddItem(default.Player_VampireEffect[i]);
			DTObjects.AddItem(Obj);
		}
	}
}

static function bool GetDropAllWeaponsWhenDead(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.Player_bDropAllWeaponsWhenDead.Normal;
		case 1 : return default.Player_bDropAllWeaponsWhenDead.Hard;
		case 2 : return default.Player_bDropAllWeaponsWhenDead.Suicidal;
		case 3 : return default.Player_bDropAllWeaponsWhenDead.HoE;
		default: return default.Player_bDropAllWeaponsWhenDead.Custom;
	}
}

static function int GetStartingWeaponAmount(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.Player_StartingWeaponAmount.Normal;
		case 1 : return default.Player_StartingWeaponAmount.Hard;
		case 2 : return default.Player_StartingWeaponAmount.Suicidal;
		case 3 : return default.Player_StartingWeaponAmount.HoE;
		default: return default.Player_StartingWeaponAmount.Custom;
	}
}

static function int GetStartingMaxHealth(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.Player_StartingMaxHealth.Normal;
		case 1 : return default.Player_StartingMaxHealth.Hard;
		case 2 : return default.Player_StartingMaxHealth.Suicidal;
		case 3 : return default.Player_StartingMaxHealth.HoE;
		default: return default.Player_StartingMaxHealth.Custom;
	}
}

static function int GetStartingMaxArmor(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.Player_StartingMaxArmor.Normal;
		case 1 : return default.Player_StartingMaxArmor.Hard;
		case 2 : return default.Player_StartingMaxArmor.Suicidal;
		case 3 : return default.Player_StartingMaxArmor.HoE;
		default: return default.Player_StartingMaxArmor.Custom;
	}
}

static function int GetStartingCarryWeight(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.Player_StartingCarryWeight.Normal;
		case 1 : return default.Player_StartingCarryWeight.Hard;
		case 2 : return default.Player_StartingCarryWeight.Suicidal;
		case 3 : return default.Player_StartingCarryWeight.HoE;
		default: return default.Player_StartingCarryWeight.Custom;
	}
}

static function int GetStartingMaxGrenadeCount(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.Player_StartingMaxGrenadeCount.Normal;
		case 1 : return default.Player_StartingMaxGrenadeCount.Hard;
		case 2 : return default.Player_StartingMaxGrenadeCount.Suicidal;
		case 3 : return default.Player_StartingMaxGrenadeCount.HoE;
		default: return default.Player_StartingMaxGrenadeCount.Custom;
	}
}

static function float GetHealAmountMultiplier(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.Player_HealAmountMultiplier.Normal;
		case 1 : return default.Player_HealAmountMultiplier.Hard;
		case 2 : return default.Player_HealAmountMultiplier.Suicidal;
		case 3 : return default.Player_HealAmountMultiplier.HoE;
		default: return default.Player_HealAmountMultiplier.Custom;
	}
}

static function float GetDamageTakenMultiplierWhileHoldingMelee(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.Player_DamageTakenMultiplierWhileHoldingMelee.Normal;
		case 1 : return default.Player_DamageTakenMultiplierWhileHoldingMelee.Hard;
		case 2 : return default.Player_DamageTakenMultiplierWhileHoldingMelee.Suicidal;
		case 3 : return default.Player_DamageTakenMultiplierWhileHoldingMelee.HoE;
		default: return default.Player_DamageTakenMultiplierWhileHoldingMelee.Custom;
	}
}

defaultproperties
{
	Name="Default__Config_Player"
}
