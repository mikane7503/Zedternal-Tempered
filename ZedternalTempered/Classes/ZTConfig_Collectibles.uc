// ===================================================================
// ZTConfig_Collectibles - Reward players for finding all map collectibles
//
// KF2 maps can have collectible actors (KFCollectibleActor) that players
// shoot to destroy. When all collectibles on a map are found, this config
// awards dosh to all living players.
//
// The system polls KFMapInfo.CollectiblesFound vs CollectiblesToFind on
// a timer. Maps with no collectibles are automatically skipped.
//
// INI (KFZedternalUnlimited.ini):
//   [ZedternalTempered.ZTConfig_Collectibles]
//   bEnabled=True
//   DoshReward=250
// ===================================================================
class ZTConfig_Collectibles extends Object config(ZedternalUnlimited);

// Whether the collectible reward system is active
var config bool bEnabled;

// Dosh awarded to each player when all collectibles are found
var config int DoshReward;

var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.bEnabled = True;
		default.DoshReward = 250;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.DoshReward = 500;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	if (default.DoshReward < 0)
	{
		`log("[DK_COLLECTIBLES] WARNING: DoshReward < 0, clamping to 0");
		default.DoshReward = 0;
	}

	`log("[DK_COLLECTIBLES] Config: bEnabled=" $ default.bEnabled $ " DoshReward=" $ default.DoshReward);
}

defaultproperties
{
	Name="Default__ZTConfig_Collectibles"
}
