// Artwork preference (client-side, per-player)
// Lives in KFZedternalReborn_LocalData.ini under [ZedternalTempered.ZTConfig_LocalArtwork]
//
// Only takes effect when the server allows player choice (Artwork_ServerMode=0).
// Default is False = original AI-generated artwork is shown.
// Set to True to see the hand-made legacy artwork instead.
class ZTConfig_LocalArtwork extends Object config(ZedternalUnlimited_Local);

var config int MODEVERSION;

// False = Original Artwork (AI-generated, default)
// True  = Legacy Artwork (hand-made)
var config bool bUseLegacyArtwork;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.bUseLegacyArtwork = false;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function bool GetUseLegacyArtwork()
{
	return default.bUseLegacyArtwork;
}

static function SetUseLegacyArtwork(bool bValue)
{
	default.bUseLegacyArtwork = bValue;
	static.StaticSaveConfig();
}

defaultproperties
{
	Name="Default__ZTConfig_LocalArtwork"
}
