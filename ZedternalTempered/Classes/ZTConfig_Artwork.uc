// Artwork preference (server-side)
// Lives in KFZedternalUnlimited.ini under [ZedternalTempered.ZTConfig_Artwork]
//
// Controls which icon set is displayed for Zedternal Unlimited perks and skills.
//   UpgradeIcon        = Original artwork (AI-generated) - the default
//   LegacyUpgradeIcon  = Legacy artwork (hand-made) - opt-in via bUseLegacyArtwork
//
// NOTE: On dedicated servers, this config is NOT available to clients.
// Server forcing (modes 1 and 2) only works on listen servers where the host is also a player.
// On dedicated servers, the setting falls through to player choice (client-side LocalData.ini).
// To support dedicated server forcing, a replicated helper class would be needed in a future update.
class ZTConfig_Artwork extends Object config(ZedternalUnlimited);

var config int MODEVERSION;

// 0 = Player Choice (default) - each player decides via their local config
// 1 = Force Legacy Artwork (hand-made) - all players see the hand-made artwork
// 2 = Force Original Artwork (AI-generated) - all players see the AI-generated artwork
var config byte Artwork_ServerMode;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Artwork_ServerMode = 0;
	}

	if (default.MODEVERSION < 1)
	{
		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Artwork_ServerMode = 0;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	if (default.Artwork_ServerMode > 2)
	{
		`log("[DK_ARTWORK] Config Error: Artwork_ServerMode=" $ default.Artwork_ServerMode $ " is invalid. Setting to 0 (Player Choice).");
		default.Artwork_ServerMode = 0;
	}
}

static function byte GetServerMode()
{
	return default.Artwork_ServerMode;
}

defaultproperties
{
	Name="Default__ZTConfig_Artwork"
}
