class Config_ZedBuff extends Config_Common
	config(ZedternalReborn_Events);

var config int MODEVERSION;

var config S_Difficulty_Bool ZedBuff_bEnable;
var config S_Difficulty_Bool ZedBuff_bBonusDoshGivenPerBuff;
var config S_Difficulty_Bool ZedBuff_bBonusTraderTimeGivenPerBuff;

var config S_Difficulty_Int ZedBuff_TraderTimeBonus;
var config S_Difficulty_Int ZedBuff_DoshBonus;

struct S_BuffWaves
{
	var array<int> Waves;
};
var config S_BuffWaves ZedBuff_BuffWaves;

struct S_ZedBuff
{
	var string Path;
	var int MinWave, MaxWave;
};
var config array<S_ZedBuff> ZedBuff_ZedBuffs;

static function UpdateConfig()
{
	local int i;

	if (default.MODEVERSION < 1)
	{
		default.ZedBuff_bEnable.Normal = True;
		default.ZedBuff_bEnable.Hard = True;
		default.ZedBuff_bEnable.Suicidal = True;
		default.ZedBuff_bEnable.HoE = True;
		default.ZedBuff_bEnable.Custom = True;

		default.ZedBuff_bBonusDoshGivenPerBuff.Normal = False;
		default.ZedBuff_bBonusDoshGivenPerBuff.Hard = False;
		default.ZedBuff_bBonusDoshGivenPerBuff.Suicidal = False;
		default.ZedBuff_bBonusDoshGivenPerBuff.HoE = False;
		default.ZedBuff_bBonusDoshGivenPerBuff.Custom = False;

		default.ZedBuff_bBonusTraderTimeGivenPerBuff.Normal = False;
		default.ZedBuff_bBonusTraderTimeGivenPerBuff.Hard = False;
		default.ZedBuff_bBonusTraderTimeGivenPerBuff.Suicidal = False;
		default.ZedBuff_bBonusTraderTimeGivenPerBuff.HoE = False;
		default.ZedBuff_bBonusTraderTimeGivenPerBuff.Custom = False;

		default.ZedBuff_TraderTimeBonus.Normal = 25;
		default.ZedBuff_TraderTimeBonus.Hard = 25;
		default.ZedBuff_TraderTimeBonus.Suicidal = 25;
		default.ZedBuff_TraderTimeBonus.HoE = 25;
		default.ZedBuff_TraderTimeBonus.Custom = 25;

		default.ZedBuff_DoshBonus.Normal = 500;
		default.ZedBuff_DoshBonus.Hard = 500;
		default.ZedBuff_DoshBonus.Suicidal = 500;
		default.ZedBuff_DoshBonus.HoE = 500;
		default.ZedBuff_DoshBonus.Custom = 500;

		default.ZedBuff_BuffWaves.Waves.Length = 8;
		default.ZedBuff_BuffWaves.Waves[0] = 5;
		default.ZedBuff_BuffWaves.Waves[1] = 9;
		default.ZedBuff_BuffWaves.Waves[2] = 13;
		default.ZedBuff_BuffWaves.Waves[3] = 17;
		default.ZedBuff_BuffWaves.Waves[4] = 21;
		default.ZedBuff_BuffWaves.Waves[5] = 25;
		default.ZedBuff_BuffWaves.Waves[6] = 29;
		default.ZedBuff_BuffWaves.Waves[7] = 33;

		default.ZedBuff_ZedBuffs.Length = 22;
		default.ZedBuff_ZedBuffs[0].Path = "ZedternalReborn.WMZedBuff_Slasher_Enraged";
		default.ZedBuff_ZedBuffs[1].Path = "ZedternalReborn.WMZedBuff_Crawler_Health";
		default.ZedBuff_ZedBuffs[2].Path = "ZedternalReborn.WMZedBuff_Crawler_Faster";
		default.ZedBuff_ZedBuffs[3].Path = "ZedternalReborn.WMZedBuff_Gorefast_Damage";
		default.ZedBuff_ZedBuffs[4].Path = "ZedternalReborn.WMZedBuff_Gorefast_Enraged";
		default.ZedBuff_ZedBuffs[5].Path = "ZedternalReborn.WMZedBuff_SpawnRate";
		default.ZedBuff_ZedBuffs[6].Path = "ZedternalReborn.WMZedBuff_Clot_Stronger";
		default.ZedBuff_ZedBuffs[7].Path = "ZedternalReborn.WMZedBuff_Stalker_Faster";
		for (i = 0; i <= 7; ++i)
		{
			default.ZedBuff_ZedBuffs[i].MinWave = 0;
			default.ZedBuff_ZedBuffs[i].MaxWave = 13;
		}

		default.ZedBuff_ZedBuffs[8].Path = "ZedternalReborn.WMZedBuff_Siren_ScreamRate";
		default.ZedBuff_ZedBuffs[9].Path = "ZedternalReborn.WMZedBuff_Health";
		default.ZedBuff_ZedBuffs[10].Path = "ZedternalReborn.WMZedBuff_Damage";
		default.ZedBuff_ZedBuffs[11].Path = "ZedternalReborn.WMZedBuff_Speed";
		default.ZedBuff_ZedBuffs[12].Path = "ZedternalReborn.WMZedBuff_PukeMine";
		default.ZedBuff_ZedBuffs[13].Path = "ZedternalReborn.WMZedBuff_Siren_Heal";
		default.ZedBuff_ZedBuffs[14].Path = "ZedternalReborn.WMZedBuff_Hostility";
		for (i = 8; i <= 14; ++i)
		{
			default.ZedBuff_ZedBuffs[i].MinWave = 9;
			default.ZedBuff_ZedBuffs[i].MaxWave = 21;
		}

		default.ZedBuff_ZedBuffs[15].Path = "ZedternalReborn.WMZedBuff_Husk_SuicideRate";
		default.ZedBuff_ZedBuffs[16].Path = "ZedternalReborn.WMZedBuff_Scrake_Enraged";
		default.ZedBuff_ZedBuffs[17].Path = "ZedternalReborn.WMZedBuff_Fleshpound_Stronger";
		default.ZedBuff_ZedBuffs[18].Path = "ZedternalReborn.WMZedBuff_Health_II";
		default.ZedBuff_ZedBuffs[19].Path = "ZedternalReborn.WMZedBuff_Damage_II";
		default.ZedBuff_ZedBuffs[20].Path = "ZedternalReborn.WMZedBuff_Speed_II";
		default.ZedBuff_ZedBuffs[21].Path = "ZedternalReborn.WMZedBuff_Beefcake";
		for (i = 15; i <= 21; ++i)
		{
			default.ZedBuff_ZedBuffs[i].MinWave = 17;
			default.ZedBuff_ZedBuffs[i].MaxWave = 999;
		}
	}

	if (default.MODEVERSION < class'ZedternalReborn.Config_Base'.const.CurrentVersion)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.ZedBuff_TraderTimeBonus.Normal = 25;
		default.ZedBuff_TraderTimeBonus.Hard = 25;
		default.ZedBuff_TraderTimeBonus.Suicidal = 25;
		default.ZedBuff_TraderTimeBonus.HOE = 25;
		default.ZedBuff_TraderTimeBonus.Custom = 25;
		default.ZedBuff_DoshBonus.Normal = 1500;
		default.ZedBuff_DoshBonus.Hard = 1500;
		default.ZedBuff_DoshBonus.Suicidal = 1500;
		default.ZedBuff_DoshBonus.HOE = 1500;
		default.ZedBuff_DoshBonus.Custom = 1500;
		default.ZedBuff_ZedBuffs.Length = 22;
		default.ZedBuff_ZedBuffs[0].Path = "ZedternalReborn.WMZedBuff_Slasher_Enraged";
		default.ZedBuff_ZedBuffs[0].MinWave = 0;
		default.ZedBuff_ZedBuffs[0].MaxWave = 12;
		default.ZedBuff_ZedBuffs[1].Path = "ZedternalReborn.WMZedBuff_Crawler_Health";
		default.ZedBuff_ZedBuffs[1].MinWave = 0;
		default.ZedBuff_ZedBuffs[1].MaxWave = 14;
		default.ZedBuff_ZedBuffs[2].Path = "ZedternalReborn.WMZedBuff_Crawler_Faster";
		default.ZedBuff_ZedBuffs[2].MinWave = 0;
		default.ZedBuff_ZedBuffs[2].MaxWave = 12;
		default.ZedBuff_ZedBuffs[3].Path = "ZedternalReborn.WMZedBuff_Gorefast_Damage";
		default.ZedBuff_ZedBuffs[3].MinWave = 0;
		default.ZedBuff_ZedBuffs[3].MaxWave = 12;
		default.ZedBuff_ZedBuffs[4].Path = "ZedternalReborn.WMZedBuff_Gorefast_Enraged";
		default.ZedBuff_ZedBuffs[4].MinWave = 0;
		default.ZedBuff_ZedBuffs[4].MaxWave = 12;
		default.ZedBuff_ZedBuffs[5].Path = "ZedternalReborn.WMZedBuff_SpawnRate";
		default.ZedBuff_ZedBuffs[5].MinWave = 0;
		default.ZedBuff_ZedBuffs[5].MaxWave = 999;
		default.ZedBuff_ZedBuffs[6].Path = "ZedternalReborn.WMZedBuff_Clot_Stronger";
		default.ZedBuff_ZedBuffs[6].MinWave = 0;
		default.ZedBuff_ZedBuffs[6].MaxWave = 14;
		default.ZedBuff_ZedBuffs[7].Path = "ZedternalReborn.WMZedBuff_Stalker_Faster";
		default.ZedBuff_ZedBuffs[7].MinWave = 0;
		default.ZedBuff_ZedBuffs[7].MaxWave = 14;
		default.ZedBuff_ZedBuffs[8].Path = "ZedternalReborn.WMZedBuff_Siren_ScreamRate";
		default.ZedBuff_ZedBuffs[8].MinWave = 14;
		default.ZedBuff_ZedBuffs[8].MaxWave = 999;
		default.ZedBuff_ZedBuffs[9].Path = "ZedternalReborn.WMZedBuff_Health";
		default.ZedBuff_ZedBuffs[9].MinWave = 14;
		default.ZedBuff_ZedBuffs[9].MaxWave = 24;
		default.ZedBuff_ZedBuffs[10].Path = "ZedternalReborn.WMZedBuff_Damage";
		default.ZedBuff_ZedBuffs[10].MinWave = 14;
		default.ZedBuff_ZedBuffs[10].MaxWave = 24;
		default.ZedBuff_ZedBuffs[11].Path = "ZedternalReborn.WMZedBuff_Speed";
		default.ZedBuff_ZedBuffs[11].MinWave = 14;
		default.ZedBuff_ZedBuffs[11].MaxWave = 24;
		default.ZedBuff_ZedBuffs[12].Path = "ZedternalReborn.WMZedBuff_PukeMine";
		default.ZedBuff_ZedBuffs[12].MinWave = 0;
		default.ZedBuff_ZedBuffs[12].MaxWave = 14;
		default.ZedBuff_ZedBuffs[13].Path = "ZedternalReborn.WMZedBuff_Siren_Heal";
		default.ZedBuff_ZedBuffs[13].MinWave = 14;
		default.ZedBuff_ZedBuffs[13].MaxWave = 999;
		default.ZedBuff_ZedBuffs[14].Path = "ZedternalReborn.WMZedBuff_Hostility";
		default.ZedBuff_ZedBuffs[14].MinWave = 14;
		default.ZedBuff_ZedBuffs[14].MaxWave = 999;
		default.ZedBuff_ZedBuffs[15].Path = "ZedternalReborn.WMZedBuff_Husk_SuicideRate";
		default.ZedBuff_ZedBuffs[15].MinWave = 0;
		default.ZedBuff_ZedBuffs[15].MaxWave = 999;
		default.ZedBuff_ZedBuffs[16].Path = "ZedternalReborn.WMZedBuff_Scrake_Enraged";
		default.ZedBuff_ZedBuffs[16].MinWave = 30;
		default.ZedBuff_ZedBuffs[16].MaxWave = 999;
		default.ZedBuff_ZedBuffs[17].Path = "ZedternalReborn.WMZedBuff_Fleshpound_Stronger";
		default.ZedBuff_ZedBuffs[17].MinWave = 20;
		default.ZedBuff_ZedBuffs[17].MaxWave = 999;
		default.ZedBuff_ZedBuffs[18].Path = "ZedternalReborn.WMZedBuff_Health_II";
		default.ZedBuff_ZedBuffs[18].MinWave = 20;
		default.ZedBuff_ZedBuffs[18].MaxWave = 999;
		default.ZedBuff_ZedBuffs[19].Path = "ZedternalReborn.WMZedBuff_Damage_II";
		default.ZedBuff_ZedBuffs[19].MinWave = 20;
		default.ZedBuff_ZedBuffs[19].MaxWave = 999;
		default.ZedBuff_ZedBuffs[20].Path = "ZedternalReborn.WMZedBuff_Speed_II";
		default.ZedBuff_ZedBuffs[20].MinWave = 30;
		default.ZedBuff_ZedBuffs[20].MaxWave = 999;
		default.ZedBuff_ZedBuffs[21].Path = "ZedternalReborn.WMZedBuff_Beefcake";
		default.ZedBuff_ZedBuffs[21].MinWave = 30;
		default.ZedBuff_ZedBuffs[21].MaxWave = 999;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i, temp;

	for (i = 0; i < NumberOfDiffs; ++i)
	{
		if (GetStructValueInt(default.ZedBuff_TraderTimeBonus, i) < 0)
		{
			LogBadStructConfigMessage(i, "ZedBuff_TraderTimeBonus",
				string(GetStructValueInt(default.ZedBuff_TraderTimeBonus, i)),
				"0", "0 seconds, no bonus trader time", "value >= 0");
			SetStructValueInt(default.ZedBuff_TraderTimeBonus, i, 0);
		}

		if (GetStructValueInt(default.ZedBuff_DoshBonus, i) < 0)
		{
			LogBadStructConfigMessage(i, "ZedBuff_DoshBonus",
				string(GetStructValueInt(default.ZedBuff_DoshBonus, i)),
				"0", "0 dosh, no bonus dosh", "value >= 0");
			SetStructValueInt(default.ZedBuff_DoshBonus, i, 0);
		}
	}

	for (i = 0; i < default.ZedBuff_BuffWaves.Waves.Length; ++i)
	{
		if (default.ZedBuff_BuffWaves.Waves[i] < 0)
		{
			LogBadConfigMessage("ZedBuff_BuffWaves - Position" @ string(i + 1),
				string(default.ZedBuff_BuffWaves.Waves[i]),
				"0", "wave 0, never activated", "value >= 0");
			default.ZedBuff_BuffWaves.Waves[i] = 0;
		}
	}

	for (i = 0; i < default.ZedBuff_ZedBuffs.Length; ++i)
	{
		if (default.ZedBuff_ZedBuffs[i].MinWave < 0)
		{
			LogBadConfigMessage("ZedBuff_ZedBuffs - Line" @ string(i + 1) @ "- MinWave",
				string(default.ZedBuff_ZedBuffs[i].MinWave),
				"0", "wave 0", "value >= 0");
			default.ZedBuff_ZedBuffs[i].MinWave = 0;
		}

		if (default.ZedBuff_ZedBuffs[i].MaxWave < 0)
		{
			LogBadConfigMessage("ZedBuff_ZedBuffs - Line" @ string(i + 1) @ "- MaxWave",
				string(default.ZedBuff_ZedBuffs[i].MaxWave),
				"0", "wave 0", "value >= 0");
			default.ZedBuff_ZedBuffs[i].MaxWave = 0;
		}

		if (default.ZedBuff_ZedBuffs[i].MinWave > default.ZedBuff_ZedBuffs[i].MaxWave)
		{
			LogBadFlipConfigMessage("ZedBuff_ZedBuffs - Line" @ string(i + 1), "MinWave", "MaxWave");
			temp = default.ZedBuff_ZedBuffs[i].MinWave;
			default.ZedBuff_ZedBuffs[i].MinWave = default.ZedBuff_ZedBuffs[i].MaxWave;
			default.ZedBuff_ZedBuffs[i].MaxWave = temp;
		}
	}
}

static function LoadConfigObjects(out array<S_ZedBuff> ValidBuffs, out array< class<WMZedBuff> > BuffObjects)
{
	local int i, Ins;
	local class<WMZedBuff> Obj;

	ValidBuffs.Length = 0;
	BuffObjects.Length = 0;

	for (i = 0; i < default.ZedBuff_ZedBuffs.Length; ++i)
	{
		Obj = class<WMZedBuff>(DynamicLoadObject(default.ZedBuff_ZedBuffs[i].Path, class'Class', True));
		if (Obj == None)
		{
			LogBadLoadObjectConfigMessage("ZedBuff_ZedBuffs", i + 1, default.ZedBuff_ZedBuffs[i].Path);
		}
		else
		{
			ValidBuffs.AddItem(default.ZedBuff_ZedBuffs[i]);

			if (class'ZedternalReborn.WMBinaryOps'.static.BinarySearchUnique(BuffObjects, PathName(Obj), Ins))
				BuffObjects.InsertItem(Ins, Obj);
		}
	}
}

static function bool GetZedBuffEnable(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.ZedBuff_bEnable.Normal;
		case 1 : return default.ZedBuff_bEnable.Hard;
		case 2 : return default.ZedBuff_bEnable.Suicidal;
		case 3 : return default.ZedBuff_bEnable.HoE;
		default: return default.ZedBuff_bEnable.Custom;
	}
}

static function bool GetBonusDoshGivenPerBuff(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.ZedBuff_bBonusDoshGivenPerBuff.Normal;
		case 1 : return default.ZedBuff_bBonusDoshGivenPerBuff.Hard;
		case 2 : return default.ZedBuff_bBonusDoshGivenPerBuff.Suicidal;
		case 3 : return default.ZedBuff_bBonusDoshGivenPerBuff.HoE;
		default: return default.ZedBuff_bBonusDoshGivenPerBuff.Custom;
	}
}

static function bool GetBonusTraderTimeGivenPerBuff(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.ZedBuff_bBonusTraderTimeGivenPerBuff.Normal;
		case 1 : return default.ZedBuff_bBonusTraderTimeGivenPerBuff.Hard;
		case 2 : return default.ZedBuff_bBonusTraderTimeGivenPerBuff.Suicidal;
		case 3 : return default.ZedBuff_bBonusTraderTimeGivenPerBuff.HoE;
		default: return default.ZedBuff_bBonusTraderTimeGivenPerBuff.Custom;
	}
}

static function bool IsWaveBuffZed(int Wave, out int Count)
{
	local int i;

	Count = 0;
	for (i = 0; i < default.ZedBuff_BuffWaves.Waves.Length; ++i)
	{
		if (default.ZedBuff_BuffWaves.Waves[i] == Wave)
			++Count;
	}

	return Count > 0;
}

static function int GetTraderTimeBonus(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.ZedBuff_TraderTimeBonus.Normal;
		case 1 : return default.ZedBuff_TraderTimeBonus.Hard;
		case 2 : return default.ZedBuff_TraderTimeBonus.Suicidal;
		case 3 : return default.ZedBuff_TraderTimeBonus.HoE;
		default: return default.ZedBuff_TraderTimeBonus.Custom;
	}
}

static function int GetDoshBonus(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.ZedBuff_DoshBonus.Normal;
		case 1 : return default.ZedBuff_DoshBonus.Hard;
		case 2 : return default.ZedBuff_DoshBonus.Suicidal;
		case 3 : return default.ZedBuff_DoshBonus.HoE;
		default: return default.ZedBuff_DoshBonus.Custom;
	}
}

defaultproperties
{
	Name="Default__Config_ZedBuff"
}
