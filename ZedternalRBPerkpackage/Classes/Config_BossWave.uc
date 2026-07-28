// ===================================================================
// Config_BossWave - Boss Wave Configuration System
// Manages which boss waves can appear and when
// ===================================================================
class Config_BossWave extends Object
	config(DKBossWaves);

var config int MODEVERSION;

struct S_BossWave
{
	var string Path;
	var int MinWave, MaxWave;
	var bool bEnabled;
};

var config array<S_BossWave> BossWaves;

// Force specific boss waves on specific wave numbers (for testing)
struct S_ForcedBossWave
{
	var int Wave;
	var string BossWavePath;
	var float Probability;
};

var config array<S_ForcedBossWave> ForcedBossWaves;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.BossWaves.Length = 5;
		
		// Patriarch Onslaught
		default.BossWaves[0].Path = "ZedternalRBPerkpackage.DKSpecialWave_Patriarchs";
		default.BossWaves[0].MinWave = 21;
		default.BossWaves[0].MaxWave = 999;
		default.BossWaves[0].bEnabled = true;
		
		// Hans Volter Onslaught
		default.BossWaves[1].Path = "ZedternalRBPerkpackage.DKSpecialWave_HansVolters";
		default.BossWaves[1].MinWave = 21;
		default.BossWaves[1].MaxWave = 999;
		default.BossWaves[1].bEnabled = true;
		
		// Matriarch Onslaught
		default.BossWaves[2].Path = "ZedternalRBPerkpackage.DKSpecialWave_Matriarchs";
		default.BossWaves[2].MinWave = 21;
		default.BossWaves[2].MaxWave = 999;
		default.BossWaves[2].bEnabled = true;
		
		// Fleshpound King Onslaught
		default.BossWaves[3].Path = "ZedternalRBPerkpackage.DKSpecialWave_FleshpoundKings";
		default.BossWaves[3].MinWave = 21;
		default.BossWaves[3].MaxWave = 999;
		default.BossWaves[3].bEnabled = true;
		
		// Bloat King Onslaught
		default.BossWaves[4].Path = "ZedternalRBPerkpackage.DKSpecialWave_BloatKings";
		default.BossWaves[4].MinWave = 21;
		default.BossWaves[4].MaxWave = 999;
		default.BossWaves[4].bEnabled = true;
		
		// Forced boss waves for testing (empty by default)
		default.ForcedBossWaves.Length = 0;
		
		// Example (commented out):
		// To force Patriarch Onslaught on wave 1, add this to your DKBossWaves.ini:
		// ForcedBossWaves=(Wave=1,BossWavePath="ZedternalRBPerkpackage.DKSpecialWave_Patriarchs",Probability=1.0)
		
		default.MODEVERSION = 1;
		StaticSaveConfig();
		
		`log("DK Config: Created DKBossWaves.ini with default boss wave settings");
	}
}

static function CheckBasicConfigValues()
{
	local int i, temp;
	
	for (i = 0; i < default.BossWaves.Length; i++)
	{
		if (default.BossWaves[i].MinWave < 0)
		{
			`log("DK Config: BossWaves - Line" @ string(i + 1) @ "- MinWave is" @ default.BossWaves[i].MinWave @ "but must be >= 0. Setting to 0.");
			default.BossWaves[i].MinWave = 0;
		}
		
		if (default.BossWaves[i].MaxWave < 0)
		{
			`log("DK Config: BossWaves - Line" @ string(i + 1) @ "- MaxWave is" @ default.BossWaves[i].MaxWave @ "but must be >= 0. Setting to 0.");
			default.BossWaves[i].MaxWave = 0;
		}
		
		if (default.BossWaves[i].MinWave > default.BossWaves[i].MaxWave)
		{
			`log("DK Config: BossWaves - Line" @ string(i + 1) @ "- MinWave (" @ default.BossWaves[i].MinWave @ ") is greater than MaxWave (" @ default.BossWaves[i].MaxWave @ "). Swapping values.");
			temp = default.BossWaves[i].MinWave;
			default.BossWaves[i].MinWave = default.BossWaves[i].MaxWave;
			default.BossWaves[i].MaxWave = temp;
		}
	}
	
	// Validate forced boss waves
	for (i = 0; i < default.ForcedBossWaves.Length; i++)
	{
		if (default.ForcedBossWaves[i].Wave < 0)
		{
			`log("DK Config: ForcedBossWaves - Line" @ string(i + 1) @ "- Wave is" @ default.ForcedBossWaves[i].Wave @ "but must be >= 0. Setting to 0.");
			default.ForcedBossWaves[i].Wave = 0;
		}
		
		if (default.ForcedBossWaves[i].Probability < 0.0f)
		{
			`log("DK Config: ForcedBossWaves - Line" @ string(i + 1) @ "- Probability is" @ default.ForcedBossWaves[i].Probability @ "but must be >= 0.0. Setting to 0.0.");
			default.ForcedBossWaves[i].Probability = 0.0f;
		}
		
		if (default.ForcedBossWaves[i].Probability > 1.0f)
		{
			`log("DK Config: ForcedBossWaves - Line" @ string(i + 1) @ "- Probability is" @ default.ForcedBossWaves[i].Probability @ "but must be <= 1.0. Setting to 1.0.");
			default.ForcedBossWaves[i].Probability = 1.0f;
		}
	}
}

static function LoadConfigObjects(out array<S_BossWave> ValidWaves, out array< class<WMSpecialWave> > WaveObjects)
{
	local int i;
	local class<WMSpecialWave> Obj;
	
	ValidWaves.Length = 0;
	WaveObjects.Length = 0;
	
	for (i = 0; i < default.BossWaves.Length; i++)
	{
		if (!default.BossWaves[i].bEnabled)
		{
			`log("DK BossWave Config: Skipping disabled boss wave:" @ default.BossWaves[i].Path);
			continue;
		}
		
		Obj = class<WMSpecialWave>(DynamicLoadObject(default.BossWaves[i].Path, class'Class', true));
		if (Obj == None)
		{
			`log("DK BossWave Config: ERROR - Failed to load boss wave class:" @ default.BossWaves[i].Path);
		}
		else
		{
			ValidWaves.AddItem(default.BossWaves[i]);
			
			// Add to wave objects list (avoid duplicates)
			if (WaveObjects.Find(Obj) == INDEX_NONE)
			{
				WaveObjects.AddItem(Obj);
			}
			
			`log("DK BossWave Config: Loaded boss wave:" @ default.BossWaves[i].Path @ "(" @ default.BossWaves[i].MinWave @ "-" @ default.BossWaves[i].MaxWave @ ")");
		}
	}
}

static function bool CanBossWaveAppear(class<WMSpecialWave> BossWaveClass, int CurrentWave)
{
	local int i;
	local string BossPath;
	
	BossPath = PathName(BossWaveClass);
	
	for (i = 0; i < default.BossWaves.Length; i++)
	{
		if (default.BossWaves[i].Path ~= BossPath && default.BossWaves[i].bEnabled)
		{
			if (CurrentWave >= default.BossWaves[i].MinWave && CurrentWave <= default.BossWaves[i].MaxWave)
			{
				return true;
			}
		}
	}
	
	return false;
}

// Check if this wave number has a forced boss wave
static function bool IsBossWaveForced(int WaveNum, out string ForcedBossPath, out float Probability)
{
	local int i;
	
	for (i = 0; i < default.ForcedBossWaves.Length; i++)
	{
		if (default.ForcedBossWaves[i].Wave == WaveNum)
		{
			ForcedBossPath = default.ForcedBossWaves[i].BossWavePath;
			Probability = default.ForcedBossWaves[i].Probability;
			`log("DK BossWave Config: Wave" @ WaveNum @ "has forced boss wave:" @ ForcedBossPath @ "with probability" @ Probability);
			return true;
		}
	}
	
	return false;
}

defaultproperties
{
	Name="Default__Config_BossWave"
}