class Config_SpecialWave extends Config_Common
	config(ZedternalReborn_Events);

var config int MODEVERSION;

var config S_Difficulty_Bool SpecialWave_bAllowed;
var config S_Difficulty_Float SpecialWave_Probability;
var config S_Difficulty_Float SpecialWave_DoubleProbability;

struct S_SpecialWave
{
	var string Path;
	var int MinWave, MaxWave;
};
var config array<S_SpecialWave> SpecialWave_SpecialWaves;

static function UpdateConfig()
{
	local int i;

	if (default.MODEVERSION < 1)
	{
		default.SpecialWave_bAllowed.Normal = True;
		default.SpecialWave_bAllowed.Hard = True;
		default.SpecialWave_bAllowed.Suicidal = True;
		default.SpecialWave_bAllowed.HoE = True;
		default.SpecialWave_bAllowed.Custom = True;

		default.SpecialWave_Probability.Normal = 0.27f;
		default.SpecialWave_Probability.Hard = 0.27f;
		default.SpecialWave_Probability.Suicidal = 0.27f;
		default.SpecialWave_Probability.HoE = 0.27f;
		default.SpecialWave_Probability.Custom = 0.27f;

		default.SpecialWave_DoubleProbability.Normal = 0.22f;
		default.SpecialWave_DoubleProbability.Hard = 0.22f;
		default.SpecialWave_DoubleProbability.Suicidal = 0.22f;
		default.SpecialWave_DoubleProbability.HoE = 0.22f;
		default.SpecialWave_DoubleProbability.Custom = 0.22f;

		default.SpecialWave_SpecialWaves.Length = 42;
		default.SpecialWave_SpecialWaves[0].Path = "ZedternalReborn.WMSpecialWave_ClotBuster";
		default.SpecialWave_SpecialWaves[1].Path = "ZedternalReborn.WMSpecialWave_Popcorn";
		default.SpecialWave_SpecialWaves[2].Path = "ZedternalReborn.WMSpecialWave_CatchMe";
		default.SpecialWave_SpecialWaves[3].Path = "ZedternalReborn.WMSpecialWave_Dosh";
		default.SpecialWave_SpecialWaves[4].Path = "ZedternalReborn.WMSpecialWave_DoubleDamage";
		default.SpecialWave_SpecialWaves[5].Path = "ZedternalReborn.WMSpecialWave_Pop";
		default.SpecialWave_SpecialWaves[6].Path = "ZedternalReborn.WMSpecialWave_GoredFast";
		default.SpecialWave_SpecialWaves[7].Path = "ZedternalReborn.WMSpecialWave_Haemorrhage";
		default.SpecialWave_SpecialWaves[8].Path = "ZedternalReborn.WMSpecialWave_Regeneration";
		default.SpecialWave_SpecialWaves[9].Path = "ZedternalReborn.WMSpecialWave_Locked";
		default.SpecialWave_SpecialWaves[10].Path = "ZedternalReborn.WMSpecialWave_GiftFromAbove";
		default.SpecialWave_SpecialWaves[11].Path = "ZedternalReborn.WMSpecialWave_Vampire";
		default.SpecialWave_SpecialWaves[12].Path = "ZedternalReborn.WMSpecialWave_BuffUp";
		default.SpecialWave_SpecialWaves[13].Path = "ZedternalReborn.WMSpecialWave_Shrink";
		default.SpecialWave_SpecialWaves[14].Path = "ZedternalReborn.WMSpecialWave_Virus";
		default.SpecialWave_SpecialWaves[15].Path = "ZedternalReborn.WMSpecialWave_Earthquake";
		default.SpecialWave_SpecialWaves[16].Path = "ZedternalReborn.WMSpecialWave_UnlimitedAmmo";
		default.SpecialWave_SpecialWaves[17].Path = "ZedternalReborn.WMSpecialWave_Featherweight";
		default.SpecialWave_SpecialWaves[18].Path = "ZedternalReborn.WMSpecialWave_GodMode";
		default.SpecialWave_SpecialWaves[19].Path = "ZedternalReborn.WMSpecialWave_Chaos";
		default.SpecialWave_SpecialWaves[20].Path = "ZedternalReborn.WMSpecialWave_Fireworks";
		for (i = 0; i <= 20; ++i)
		{
			default.SpecialWave_SpecialWaves[i].MinWave = 0;
			default.SpecialWave_SpecialWaves[i].MaxWave = 999;
		}

		default.SpecialWave_SpecialWaves[21].Path = "ZedternalReborn.WMSpecialWave_Phoenix";
		default.SpecialWave_SpecialWaves[22].Path = "ZedternalReborn.WMSpecialWave_Predator";
		for (i = 21; i <= 22; ++i)
		{
			default.SpecialWave_SpecialWaves[i].MinWave = 3;
			default.SpecialWave_SpecialWaves[i].MaxWave = 999;
		}

		default.SpecialWave_SpecialWaves[23].Path = "ZedternalReborn.WMSpecialWave_UpUpDecay";
		default.SpecialWave_SpecialWaves[24].Path = "ZedternalReborn.WMSpecialWave_Division";
		default.SpecialWave_SpecialWaves[25].Path = "ZedternalReborn.WMSpecialWave_Emperor";
		default.SpecialWave_SpecialWaves[26].Path = "ZedternalReborn.WMSpecialWave_Lethargic";
		default.SpecialWave_SpecialWaves[27].Path = "ZedternalReborn.WMSpecialWave_Titans";
		for (i = 23; i <= 27; ++i)
		{
			default.SpecialWave_SpecialWaves[i].MinWave = 3;
			default.SpecialWave_SpecialWaves[i].MaxWave = 10;
		}

		default.SpecialWave_SpecialWaves[28].Path = "ZedternalReborn.WMSpecialWave_BobbleZed";
		default.SpecialWave_SpecialWaves[29].Path = "ZedternalReborn.WMSpecialWave_Acceleration";
		default.SpecialWave_SpecialWaves[30].Path = "ZedternalReborn.WMSpecialWave_HellFire";
		default.SpecialWave_SpecialWaves[31].Path = "ZedternalReborn.WMSpecialWave_FiveAlarmSiren";
		default.SpecialWave_SpecialWaves[32].Path = "ZedternalReborn.WMSpecialWave_Poundamonium";
		default.SpecialWave_SpecialWaves[33].Path = "ZedternalReborn.WMSpecialWave_Pesticide";
		default.SpecialWave_SpecialWaves[34].Path = "ZedternalReborn.WMSpecialWave_ToxicNightmare";
		default.SpecialWave_SpecialWaves[35].Path = "ZedternalReborn.WMSpecialWave_BloodyChainsaw";
		default.SpecialWave_SpecialWaves[36].Path = "ZedternalReborn.WMSpecialWave_MechanicalProblem";
		default.SpecialWave_SpecialWaves[37].Path = "ZedternalReborn.WMSpecialWave_PurpleAlert";
		for (i = 28; i <= 37; ++i)
		{
			default.SpecialWave_SpecialWaves[i].MinWave = 3;
			default.SpecialWave_SpecialWaves[i].MaxWave = 15;
		}

		default.SpecialWave_SpecialWaves[38].Path = "ZedternalReborn.WMSpecialWave_TinyTerror";
		default.SpecialWave_SpecialWaves[39].Path = "ZedternalReborn.WMSpecialWave_BackupPlan";
		for (i = 38; i <= 39; ++i)
		{
			default.SpecialWave_SpecialWaves[i].MinWave = 0;
			default.SpecialWave_SpecialWaves[i].MaxWave = 7;
		}

		default.SpecialWave_SpecialWaves[40].Path = "ZedternalReborn.WMSpecialWave_TheHorde";
		default.SpecialWave_SpecialWaves[40].MinWave = 7;
		default.SpecialWave_SpecialWaves[40].MaxWave = 999;
		default.SpecialWave_SpecialWaves[41].Path = "ZedternalReborn.WMSpecialWave_InstaKill";
		default.SpecialWave_SpecialWaves[41].MinWave = 0;
		default.SpecialWave_SpecialWaves[41].MaxWave = 15;
	}

	if (default.MODEVERSION < class'ZedternalReborn.Config_Base'.const.CurrentVersion)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.SpecialWave_Probability.Normal = 0.240000f;
		default.SpecialWave_Probability.Hard = 0.240000f;
		default.SpecialWave_Probability.Suicidal = 0.240000f;
		default.SpecialWave_Probability.HOE = 0.240000f;
		default.SpecialWave_Probability.Custom = 0.240000f;
		default.SpecialWave_DoubleProbability.Normal = 0.200000f;
		default.SpecialWave_DoubleProbability.Hard = 0.200000f;
		default.SpecialWave_DoubleProbability.Suicidal = 0.200000f;
		default.SpecialWave_DoubleProbability.HOE = 0.200000f;
		default.SpecialWave_DoubleProbability.Custom = 0.200000f;
		default.SpecialWave_SpecialWaves.Length = 33;
		default.SpecialWave_SpecialWaves[0].Path = "ZedternalReborn.WMSpecialWave_ClotBuster";
		default.SpecialWave_SpecialWaves[0].MinWave = 0;
		default.SpecialWave_SpecialWaves[0].MaxWave = 4;
		default.SpecialWave_SpecialWaves[1].Path = "ZedternalReborn.WMSpecialWave_CatchMe";
		default.SpecialWave_SpecialWaves[1].MinWave = 5;
		default.SpecialWave_SpecialWaves[1].MaxWave = 15;
		default.SpecialWave_SpecialWaves[2].Path = "ZedternalReborn.WMSpecialWave_DoubleDamage";
		default.SpecialWave_SpecialWaves[2].MinWave = 0;
		default.SpecialWave_SpecialWaves[2].MaxWave = 999;
		default.SpecialWave_SpecialWaves[3].Path = "ZedternalReborn.WMSpecialWave_Pop";
		default.SpecialWave_SpecialWaves[3].MinWave = 0;
		default.SpecialWave_SpecialWaves[3].MaxWave = 999;
		default.SpecialWave_SpecialWaves[4].Path = "ZedternalReborn.WMSpecialWave_Popcorn";
		default.SpecialWave_SpecialWaves[4].MinWave = 0;
		default.SpecialWave_SpecialWaves[4].MaxWave = 4;
		default.SpecialWave_SpecialWaves[5].Path = "ZedternalReborn.WMSpecialWave_Regeneration";
		default.SpecialWave_SpecialWaves[5].MinWave = 0;
		default.SpecialWave_SpecialWaves[5].MaxWave = 999;
		default.SpecialWave_SpecialWaves[6].Path = "ZedternalReborn.WMSpecialWave_GiftFromAbove";
		default.SpecialWave_SpecialWaves[6].MinWave = 0;
		default.SpecialWave_SpecialWaves[6].MaxWave = 999;
		default.SpecialWave_SpecialWaves[7].Path = "ZedternalReborn.WMSpecialWave_Vampire";
		default.SpecialWave_SpecialWaves[7].MinWave = 0;
		default.SpecialWave_SpecialWaves[7].MaxWave = 999;
		default.SpecialWave_SpecialWaves[8].Path = "ZedternalReborn.WMSpecialWave_Earthquake";
		default.SpecialWave_SpecialWaves[8].MinWave = 0;
		default.SpecialWave_SpecialWaves[8].MaxWave = 999;
		default.SpecialWave_SpecialWaves[9].Path = "ZedternalReborn.WMSpecialWave_Featherweight";
		default.SpecialWave_SpecialWaves[9].MinWave = 0;
		default.SpecialWave_SpecialWaves[9].MaxWave = 999;
		default.SpecialWave_SpecialWaves[10].Path = "ZedternalReborn.WMSpecialWave_GoredFast";
		default.SpecialWave_SpecialWaves[10].MinWave = 4;
		default.SpecialWave_SpecialWaves[10].MaxWave = 999;
		default.SpecialWave_SpecialWaves[11].Path = "ZedternalReborn.WMSpecialWave_Haemorrhage";
		default.SpecialWave_SpecialWaves[11].MinWave = 5;
		default.SpecialWave_SpecialWaves[11].MaxWave = 999;
		default.SpecialWave_SpecialWaves[12].Path = "ZedternalReborn.WMSpecialWave_BuffUp";
		default.SpecialWave_SpecialWaves[12].MinWave = 6;
		default.SpecialWave_SpecialWaves[12].MaxWave = 999;
		default.SpecialWave_SpecialWaves[13].Path = "ZedternalReborn.WMSpecialWave_Virus";
		default.SpecialWave_SpecialWaves[13].MinWave = 3;
		default.SpecialWave_SpecialWaves[13].MaxWave = 999;
		default.SpecialWave_SpecialWaves[14].Path = "ZedternalReborn.WMSpecialWave_UnlimitedAmmo";
		default.SpecialWave_SpecialWaves[14].MinWave = 10;
		default.SpecialWave_SpecialWaves[14].MaxWave = 999;
		default.SpecialWave_SpecialWaves[15].Path = "ZedternalReborn.WMSpecialWave_Fireworks";
		default.SpecialWave_SpecialWaves[15].MinWave = 5;
		default.SpecialWave_SpecialWaves[15].MaxWave = 999;
		default.SpecialWave_SpecialWaves[16].Path = "ZedternalReborn.WMSpecialWave_BobbleZed";
		default.SpecialWave_SpecialWaves[16].MinWave = 6;
		default.SpecialWave_SpecialWaves[16].MaxWave = 999;
		default.SpecialWave_SpecialWaves[17].Path = "ZedternalReborn.WMSpecialWave_Dosh";
		default.SpecialWave_SpecialWaves[17].MinWave = 0;
		default.SpecialWave_SpecialWaves[17].MaxWave = 999;
		default.SpecialWave_SpecialWaves[18].Path = "ZedternalReborn.WMSpecialWave_GodMode";
		default.SpecialWave_SpecialWaves[18].MinWave = 0;
		default.SpecialWave_SpecialWaves[18].MaxWave = 999;
		default.SpecialWave_SpecialWaves[19].Path = "ZedternalReborn.WMSpecialWave_Chaos";
		default.SpecialWave_SpecialWaves[19].MinWave = 0;
		default.SpecialWave_SpecialWaves[19].MaxWave = 999;
		default.SpecialWave_SpecialWaves[20].Path = "ZedternalReborn.WMSpecialWave_UpUpDecay";
		default.SpecialWave_SpecialWaves[20].MinWave = 0;
		default.SpecialWave_SpecialWaves[20].MaxWave = 999;
		default.SpecialWave_SpecialWaves[21].Path = "ZedternalReborn.WMSpecialWave_Division";
		default.SpecialWave_SpecialWaves[21].MinWave = 0;
		default.SpecialWave_SpecialWaves[21].MaxWave = 999;
		default.SpecialWave_SpecialWaves[22].Path = "ZedternalReborn.WMSpecialWave_Emperor";
		default.SpecialWave_SpecialWaves[22].MinWave = 6;
		default.SpecialWave_SpecialWaves[22].MaxWave = 999;
		default.SpecialWave_SpecialWaves[23].Path = "ZedternalReborn.WMSpecialWave_Titans";
		default.SpecialWave_SpecialWaves[23].MinWave = 4;
		default.SpecialWave_SpecialWaves[23].MaxWave = 999;
		default.SpecialWave_SpecialWaves[24].Path = "ZedternalReborn.WMSpecialWave_Acceleration";
		default.SpecialWave_SpecialWaves[24].MinWave = 5;
		default.SpecialWave_SpecialWaves[24].MaxWave = 15;
		default.SpecialWave_SpecialWaves[25].Path = "ZedternalReborn.WMSpecialWave_ToxicNightmare";
		default.SpecialWave_SpecialWaves[25].MinWave = 9;
		default.SpecialWave_SpecialWaves[25].MaxWave = 999;
		default.SpecialWave_SpecialWaves[26].Path = "ZedternalReborn.WMSpecialWave_TheHorde";
		default.SpecialWave_SpecialWaves[26].MinWave = 11;
		default.SpecialWave_SpecialWaves[26].MaxWave = 999;
		default.SpecialWave_SpecialWaves[27].Path = "ZedternalReborn.WMSpecialWave_HellFire";
		default.SpecialWave_SpecialWaves[27].MinWave = 10;
		default.SpecialWave_SpecialWaves[27].MaxWave = 999;
		default.SpecialWave_SpecialWaves[28].Path = "ZedternalReborn.WMSpecialWave_FiveAlarmSiren";
		default.SpecialWave_SpecialWaves[28].MinWave = 7;
		default.SpecialWave_SpecialWaves[28].MaxWave = 999;
		default.SpecialWave_SpecialWaves[29].Path = "ZedternalReborn.WMSpecialWave_Pesticide";
		default.SpecialWave_SpecialWaves[29].MinWave = 3;
		default.SpecialWave_SpecialWaves[29].MaxWave = 9;
		default.SpecialWave_SpecialWaves[30].Path = "ZedternalReborn.WMSpecialWave_MechanicalProblem";
		default.SpecialWave_SpecialWaves[30].MinWave = 7;
		default.SpecialWave_SpecialWaves[30].MaxWave = 999;
		default.SpecialWave_SpecialWaves[31].Path = "ZedternalReborn.WMSpecialWave_Phoenix";
		default.SpecialWave_SpecialWaves[31].MinWave = 20;
		default.SpecialWave_SpecialWaves[31].MaxWave = 999;
		default.SpecialWave_SpecialWaves[32].Path = "ZedternalReborn.WMSpecialWave_Lethargic";
		default.SpecialWave_SpecialWaves[32].MinWave = 0;
		default.SpecialWave_SpecialWaves[32].MaxWave = 999;
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

		if (GetStructValueFloat(default.SpecialWave_Probability, i) < 0.0f)
		{
			LogBadStructConfigMessage(i, "SpecialWave_Probability",
				string(GetStructValueFloat(default.SpecialWave_Probability, i)),
				"0.0", "0%, never activates", "1.0 >= value >= 0.0");
			SetStructValueFloat(default.SpecialWave_Probability, i, 0.0f);
		}

		if (GetStructValueFloat(default.SpecialWave_Probability, i) > 1.0f)
		{
			LogBadStructConfigMessage(i, "SpecialWave_Probability",
				string(GetStructValueFloat(default.SpecialWave_Probability, i)),
				"1.0", "100%, always activates", "1.0 >= value >= 0.0");
			SetStructValueFloat(default.SpecialWave_Probability, i, 1.0f);
		}

		if (GetStructValueFloat(default.SpecialWave_DoubleProbability, i) < 0.0f)
		{
			LogBadStructConfigMessage(i, "SpecialWave_DoubleProbability",
				string(GetStructValueFloat(default.SpecialWave_DoubleProbability, i)),
				"0.0", "0%, never activates", "1.0 >= value >= 0.0");
			SetStructValueFloat(default.SpecialWave_DoubleProbability, i, 0.0f);
		}

		if (GetStructValueFloat(default.SpecialWave_DoubleProbability, i) > 1.0f)
		{
			LogBadStructConfigMessage(i, "SpecialWave_DoubleProbability",
				string(GetStructValueFloat(default.SpecialWave_DoubleProbability, i)),
				"1.0", "100%, always activates", "1.0 >= value >= 0.0");
			SetStructValueFloat(default.SpecialWave_DoubleProbability, i, 1.0f);
		}
	}

	for (i = 0; i < default.SpecialWave_SpecialWaves.Length; ++i)
	{
		if (default.SpecialWave_SpecialWaves[i].MinWave < 0)
		{
			LogBadConfigMessage("SpecialWave_SpecialWaves - Line" @ string(i + 1) @ "- MinWave",
				string(default.SpecialWave_SpecialWaves[i].MinWave),
				"0", "wave 0", "value >= 0");
			default.SpecialWave_SpecialWaves[i].MinWave = 0;
		}

		if (default.SpecialWave_SpecialWaves[i].MaxWave < 0)
		{
			LogBadConfigMessage("SpecialWave_SpecialWaves - Line" @ string(i + 1) @ "- MaxWave",
				string(default.SpecialWave_SpecialWaves[i].MaxWave),
				"0", "wave 0", "value >= 0");
			default.SpecialWave_SpecialWaves[i].MaxWave = 0;
		}

		if (default.SpecialWave_SpecialWaves[i].MinWave > default.SpecialWave_SpecialWaves[i].MaxWave)
		{
			LogBadFlipConfigMessage("SpecialWave_SpecialWaves - Line" @ string(i + 1), "MinWave", "MaxWave");
			temp = default.SpecialWave_SpecialWaves[i].MinWave;
			default.SpecialWave_SpecialWaves[i].MinWave = default.SpecialWave_SpecialWaves[i].MaxWave;
			default.SpecialWave_SpecialWaves[i].MaxWave = temp;
		}
	}
}

static function LoadConfigObjects(out array<S_SpecialWave> ValidWaves, out array< class<WMSpecialWave> > WaveObjects)
{
	local int i, Ins;
	local class<WMSpecialWave> Obj;

	ValidWaves.Length = 0;
	WaveObjects.Length = 0;

	for (i = 0; i < default.SpecialWave_SpecialWaves.Length; ++i)
	{
		Obj = class<WMSpecialWave>(DynamicLoadObject(default.SpecialWave_SpecialWaves[i].Path, class'Class', True));
		if (Obj == None)
		{
			LogBadLoadObjectConfigMessage("SpecialWave_SpecialWaves", i + 1, default.SpecialWave_SpecialWaves[i].Path);
		}
		else
		{
			ValidWaves.AddItem(default.SpecialWave_SpecialWaves[i]);

			if (class'ZedternalReborn.WMBinaryOps'.static.BinarySearchUnique(WaveObjects, PathName(Obj), Ins))
				WaveObjects.InsertItem(Ins, Obj);
		}
	}
}

static function bool GetSpecialWaveAllowed(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.SpecialWave_bAllowed.Normal;
		case 1 : return default.SpecialWave_bAllowed.Hard;
		case 2 : return default.SpecialWave_bAllowed.Suicidal;
		case 3 : return default.SpecialWave_bAllowed.HoE;
		default: return default.SpecialWave_bAllowed.Custom;
	}
}

static function float GetSpecialWaveProbability(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.SpecialWave_Probability.Normal;
		case 1 : return default.SpecialWave_Probability.Hard;
		case 2 : return default.SpecialWave_Probability.Suicidal;
		case 3 : return default.SpecialWave_Probability.HoE;
		default: return default.SpecialWave_Probability.Custom;
	}
}

static function float GetSpecialWaveDoubleProbability(int Difficulty)
{
	switch (Difficulty)
	{
		case 0 : return default.SpecialWave_DoubleProbability.Normal;
		case 1 : return default.SpecialWave_DoubleProbability.Hard;
		case 2 : return default.SpecialWave_DoubleProbability.Suicidal;
		case 3 : return default.SpecialWave_DoubleProbability.HoE;
		default: return default.SpecialWave_DoubleProbability.Custom;
	}
}

defaultproperties
{
	Name="Default__Config_SpecialWave"
}
