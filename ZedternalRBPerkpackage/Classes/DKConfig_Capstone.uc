// ===================================================================
// DKConfig_Capstone - Capstone Ability Configuration
//
// Controls when capstone abilities unlock and how many a player
// can have active simultaneously.
//
// Capstone Rank 1 (default level 10): First major ability unlock
// Capstone Rank 2 (default level 20): Second major ability unlock
//
// MaxActive limits how many capstones a player can have across
// ALL perks. 0 = unlimited.
// ===================================================================
class DKConfig_Capstone extends Object
	config(ZedternalUnlimited);

var config int Capstone_Rank1Level;
var config int Capstone_Rank2Level;
var config int Capstone_MaxActiveRank1;
var config int Capstone_MaxActiveRank2;
var config int MODEVERSION;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Capstone_Rank1Level = 10;
		default.Capstone_Rank2Level = 20;
		default.Capstone_MaxActiveRank1 = 0;
		default.Capstone_MaxActiveRank2 = 0;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local bool bChanged;

	if (default.Capstone_Rank1Level < 2)
	{
		`log("[DK_CAPSTONE] WARNING: Capstone_Rank1Level too low (" $ default.Capstone_Rank1Level $ "), clamping to 2");
		default.Capstone_Rank1Level = 2;
		bChanged = True;
	}

	if (default.Capstone_Rank2Level <= default.Capstone_Rank1Level)
	{
		`log("[DK_CAPSTONE] WARNING: Capstone_Rank2Level (" $ default.Capstone_Rank2Level $ ") must be > Rank1Level (" $ default.Capstone_Rank1Level $ "), setting to Rank1+10");
		default.Capstone_Rank2Level = default.Capstone_Rank1Level + 10;
		bChanged = True;
	}

	if (default.Capstone_MaxActiveRank1 < 0)
	{
		default.Capstone_MaxActiveRank1 = 0;
		bChanged = True;
	}

	if (default.Capstone_MaxActiveRank2 < 0)
	{
		default.Capstone_MaxActiveRank2 = 0;
		bChanged = True;
	}

	if (bChanged)
		static.StaticSaveConfig();

	`log("[DK_CAPSTONE] Config: Rank1=" $ default.Capstone_Rank1Level
		@ "Rank2=" $ default.Capstone_Rank2Level
		@ "MaxR1=" $ default.Capstone_MaxActiveRank1
		@ "MaxR2=" $ default.Capstone_MaxActiveRank2);
}

// Helper: get rank 1 level (for use in static perk/helper functions)
static function int GetRank1Level()
{
	return default.Capstone_Rank1Level;
}

// Helper: get rank 2 level
static function int GetRank2Level()
{
	return default.Capstone_Rank2Level;
}

defaultproperties
{
	Name="Default__DKConfig_Capstone"
}
