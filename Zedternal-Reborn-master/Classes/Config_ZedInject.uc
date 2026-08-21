class Config_ZedInject extends Config_Common
	config(ZedternalReborn_ZedWaves);

var config int MODEVERSION;

var config bool Zed_bEnableWaveGroupInjection;

struct S_ZedSpawnGroup
{
	var int Wave;
	var string ZedPath;
	var string Position;
	var int Count;
	var float Probability;
	var int MinDiff, MaxDiff;
	var bool bExclusive;
	var bool bRepeat;

	structdefaultproperties
	{
		Position = "END";
		Probability = 1.0f;
	}
};
var config array<S_ZedSpawnGroup> Zed_WaveGroupInject;

static function UpdateConfig()
{
	local int i;

	if (default.MODEVERSION < 1)
	{
		default.Zed_bEnableWaveGroupInjection = False;

		default.Zed_WaveGroupInject.Length = 3;

		default.Zed_WaveGroupInject[0].Wave = 10;
		default.Zed_WaveGroupInject[0].ZedPath = "ZedternalReborn.WMPawn_ZedCrawler_Ultra";
		default.Zed_WaveGroupInject[0].Position = "MID";
		default.Zed_WaveGroupInject[0].Count = 6;
		default.Zed_WaveGroupInject[0].Probability = 1.0f;
		default.Zed_WaveGroupInject[0].MinDiff = 0;
		default.Zed_WaveGroupInject[0].MaxDiff = 4;

		default.Zed_WaveGroupInject[1].Wave = 15;
		default.Zed_WaveGroupInject[1].ZedPath = "ZedternalReborn.WMPawn_ZedPatriarch";
		default.Zed_WaveGroupInject[1].Position = "END";
		default.Zed_WaveGroupInject[1].Count = 2;
		default.Zed_WaveGroupInject[1].Probability = 1.0f;
		default.Zed_WaveGroupInject[1].MinDiff = 2;
		default.Zed_WaveGroupInject[1].MaxDiff = 4;

		default.Zed_WaveGroupInject[2].Wave = 12;
		default.Zed_WaveGroupInject[2].ZedPath = "ZedternalReborn.WMPawn_ZedScrake_Tiny";
		default.Zed_WaveGroupInject[2].Position = "BEG";
		default.Zed_WaveGroupInject[2].Count = 3;
		default.Zed_WaveGroupInject[2].Probability = 0.5f;
		default.Zed_WaveGroupInject[2].MinDiff = 1;
		default.Zed_WaveGroupInject[2].MaxDiff = 4;
	}

	if (default.MODEVERSION < 12)
	{
		for (i = 0; i < default.Zed_WaveGroupInject.Length; ++i)
		{
			default.Zed_WaveGroupInject[i].bExclusive = False;
			default.Zed_WaveGroupInject[i].bRepeat = False;
		}
	}

	if (default.MODEVERSION < class'ZedternalReborn.Config_Base'.const.CurrentVersion)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Zed_WaveGroupInject.Length = 5;
		default.Zed_WaveGroupInject[0].Wave = 10;
		default.Zed_WaveGroupInject[0].ZedPath = "ZedternalReborn.WMPawn_ZedPatriarch";
		default.Zed_WaveGroupInject[0].Position = "MID";
		default.Zed_WaveGroupInject[0].Count = 1;
		default.Zed_WaveGroupInject[0].Probability = 1.000000f;
		default.Zed_WaveGroupInject[0].MinDiff = 0;
		default.Zed_WaveGroupInject[0].MaxDiff = 4;
		default.Zed_WaveGroupInject[0].bExclusive = False;
		default.Zed_WaveGroupInject[0].bRepeat = False;
		default.Zed_WaveGroupInject[1].Wave = 15;
		default.Zed_WaveGroupInject[1].ZedPath = "ZedternalReborn.WMPawn_ZedBloatKing";
		default.Zed_WaveGroupInject[1].Position = "MID";
		default.Zed_WaveGroupInject[1].Count = 1;
		default.Zed_WaveGroupInject[1].Probability = 1.000000f;
		default.Zed_WaveGroupInject[1].MinDiff = 0;
		default.Zed_WaveGroupInject[1].MaxDiff = 4;
		default.Zed_WaveGroupInject[1].bExclusive = False;
		default.Zed_WaveGroupInject[1].bRepeat = False;
		default.Zed_WaveGroupInject[2].Wave = 20;
		default.Zed_WaveGroupInject[2].ZedPath = "ZedternalReborn.WMPawn_ZedFleshpoundKing";
		default.Zed_WaveGroupInject[2].Position = "MID";
		default.Zed_WaveGroupInject[2].Count = 1;
		default.Zed_WaveGroupInject[2].Probability = 1.000000f;
		default.Zed_WaveGroupInject[2].MinDiff = 0;
		default.Zed_WaveGroupInject[2].MaxDiff = 4;
		default.Zed_WaveGroupInject[2].bExclusive = False;
		default.Zed_WaveGroupInject[2].bRepeat = False;
		default.Zed_WaveGroupInject[3].Wave = 25;
		default.Zed_WaveGroupInject[3].ZedPath = "ZedternalReborn.WMPawn_ZedMatriarch";
		default.Zed_WaveGroupInject[3].Position = "MID";
		default.Zed_WaveGroupInject[3].Count = 1;
		default.Zed_WaveGroupInject[3].Probability = 1.000000f;
		default.Zed_WaveGroupInject[3].MinDiff = 0;
		default.Zed_WaveGroupInject[3].MaxDiff = 4;
		default.Zed_WaveGroupInject[3].bExclusive = False;
		default.Zed_WaveGroupInject[3].bRepeat = False;
		default.Zed_WaveGroupInject[4].Wave = 30;
		default.Zed_WaveGroupInject[4].ZedPath = "ZedternalReborn.WMPawn_ZedHans";
		default.Zed_WaveGroupInject[4].Position = "MID";
		default.Zed_WaveGroupInject[4].Count = 1;
		default.Zed_WaveGroupInject[4].Probability = 1.000000f;
		default.Zed_WaveGroupInject[4].MinDiff = 0;
		default.Zed_WaveGroupInject[4].MaxDiff = 4;
		default.Zed_WaveGroupInject[4].bExclusive = False;
		default.Zed_WaveGroupInject[4].bRepeat = False;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = class'ZedternalReborn.Config_Base'.const.CurrentVersion;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i, temp;

	if (default.Zed_bEnableWaveGroupInjection)
	{
		for (i = 0; i < default.Zed_WaveGroupInject.Length; ++i)
		{
			if (default.Zed_WaveGroupInject[i].Wave < 0)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- Wave",
					string(default.Zed_WaveGroupInject[i].Wave),
					"0", "wave 0, never activated", "value >= 0");
				default.Zed_WaveGroupInject[i].Wave = 0;
			}

			if (Caps(default.Zed_WaveGroupInject[i].Position) != "BEG" && Caps(default.Zed_WaveGroupInject[i].Position) != "MID"
				&& Caps(default.Zed_WaveGroupInject[i].Position) != "END")
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- Position",
					Caps(default.Zed_WaveGroupInject[i].Position),
					"END", "END, add zeds to end of wave", "value == BEG or value == MID or value == END");
				default.Zed_WaveGroupInject[i].Position = "END";
			}

			if (default.Zed_WaveGroupInject[i].Count < 0)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- Count",
					string(default.Zed_WaveGroupInject[i].Count),
					"0", "0 zeds, disabled", "8 >= value >= 0");
				default.Zed_WaveGroupInject[i].Count = 0;
			}

			if (default.Zed_WaveGroupInject[i].Count > 8)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- Count",
					string(default.Zed_WaveGroupInject[i].Count),
					"8", "8 zeds, max zed group spawn size", "8 >= value >= 0");
				default.Zed_WaveGroupInject[i].Count = 8;
			}

			if (default.Zed_WaveGroupInject[i].Probability < 0.0f)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- Probability",
					string(default.Zed_WaveGroupInject[i].Probability),
					"0.0", "0%, never selected", "1.0 >= value >= 0.0");
				default.Zed_WaveGroupInject[i].Probability = 0.0f;
			}

			if (default.Zed_WaveGroupInject[i].Probability > 1.0f)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- Probability",
					string(default.Zed_WaveGroupInject[i].Probability),
					"1.0", "100%, always selected", "1.0 >= value >= 0.0");
				default.Zed_WaveGroupInject[i].Probability = 1.0f;
			}

			if (default.Zed_WaveGroupInject[i].MinDiff < 0)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- MinDiff",
					string(default.Zed_WaveGroupInject[i].MinDiff),
					"0", "normal difficulty", "4 >= value >= 0");
				default.Zed_WaveGroupInject[i].MinDiff = 0;
			}

			if (default.Zed_WaveGroupInject[i].MinDiff > 4)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- MinDiff",
					string(default.Zed_WaveGroupInject[i].MinDiff),
					"4", "custom difficulty", "4 >= value >= 0");
				default.Zed_WaveGroupInject[i].MinDiff = 4;
			}

			if (default.Zed_WaveGroupInject[i].MaxDiff < 0)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- MaxDiff",
					string(default.Zed_WaveGroupInject[i].MaxDiff),
					"0", "normal difficulty", "4 >= value >= 0");
				default.Zed_WaveGroupInject[i].MaxDiff = 0;
			}

			if (default.Zed_WaveGroupInject[i].MaxDiff > 4)
			{
				LogBadConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1) @ "- MaxDiff",
					string(default.Zed_WaveGroupInject[i].MaxDiff),
					"4", "custom difficulty", "4 >= value >= 0");
				default.Zed_WaveGroupInject[i].MaxDiff = 4;
			}

			if (default.Zed_WaveGroupInject[i].MinDiff > default.Zed_WaveGroupInject[i].MaxDiff)
			{
				LogBadFlipConfigMessage("Zed_WaveGroupInject - Line" @ string(i + 1), "MinDiff", "MaxDiff");
				temp = default.Zed_WaveGroupInject[i].MinDiff;
				default.Zed_WaveGroupInject[i].MinDiff = default.Zed_WaveGroupInject[i].MaxDiff;
				default.Zed_WaveGroupInject[i].MaxDiff = temp;
			}
		}
	}
	else
		SkipCheckConfigMessage("Zed_WaveGroupInject", "Zed_bEnableWaveGroupInjection");
}

static function LoadConfigObjects(out array<S_ZedSpawnGroup> ValidZedGroupInjects, out array< class<KFPawn_Monster> > ZedObjects)
{
	local int i, Ins;
	local class<KFPawn_Monster> Obj;

	ValidZedGroupInjects.Length = 0;
	ZedObjects.Length = 0;

	if (default.Zed_bEnableWaveGroupInjection)
	{
		for (i = 0; i < default.Zed_WaveGroupInject.Length; ++i)
		{
			Obj = class<KFPawn_Monster>(DynamicLoadObject(default.Zed_WaveGroupInject[i].ZedPath, class'Class', True));
			if (Obj == None)
			{
				LogBadLoadObjectConfigMessage("Zed_WaveGroupInject", i + 1, default.Zed_WaveGroupInject[i].ZedPath);
			}
			else
			{
				ValidZedGroupInjects.AddItem(default.Zed_WaveGroupInject[i]);

				if (class'ZedternalReborn.WMBinaryOps'.static.BinarySearchUnique(ZedObjects, PathName(Obj), Ins))
					ZedObjects.InsertItem(Ins, Obj);
			}
		}
	}
}

defaultproperties
{
	Name="Default__Config_ZedInject"
}
