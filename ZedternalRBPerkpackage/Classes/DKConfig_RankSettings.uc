// ===================================================================
// DKConfig_RankSettings - Server-side rank system configuration
//
// Controls how the rank system operates on this server.
// Saved to KFZedternalUnlimited.ini
// ===================================================================
class DKConfig_RankSettings extends Object
	config(ZedternalUnlimited);

// How the rank system operates on this server:
//   0 = Global rank (default) - uses player's local rank file
//   1 = Local rank - server-specific, stored per-player on server
//   2 = Disabled - no rank system at all
var config byte RankMode;

// Whether rank-up announcement messages are broadcast to all players
var config bool bRankUpBroadcastEnabled;

var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RankMode = 0;
		default.bRankUpBroadcastEnabled = True;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function bool IsRankEnabled()
{
	return default.RankMode != 2;
}

static function bool IsGlobalRank()
{
	return default.RankMode == 0;
}

static function bool IsLocalRank()
{
	return default.RankMode == 1;
}

static function bool IsRankUpBroadcastEnabled()
{
	return default.bRankUpBroadcastEnabled;
}

defaultproperties
{
	Name="Default__DKConfig_RankSettings"
}
