class DKConfig_HudPreferences extends Object
	config(ZedternalUnlimited_Local);

// ===================================================================
// CLIENT-SIDE HUD PREFERENCES
//
// Saved to ZedternalRBPerkpackage_Local.ini on the client machine.
// Auto-generated on first run with sensible defaults.
//
// HudScaleMultiplier: Multiplies the auto-calculated resolution scale.
//   1.0 = default auto scaling
//   1.2 = 20% larger than auto
//   0.8 = 20% smaller than auto
//   Set via console: DKHudScale 1.2 (or edit INI directly)
//   Reset to auto:  DKHudScale 0
//
// CardStackMaxY: Normalized screen Y limit for the card stack.
//   Cards will compress if they would exceed this boundary.
//   0.82 = cards stay in upper 82% of screen (above health bar area)
//
// CardStackMaxCards: Maximum cards shown before compression kicks in.
//   4 = start compressing after 4 simultaneous cards
//   Set higher if you have a tall monitor or small HUD scale.
// ===================================================================

var config float HudScaleMultiplier;
var config float CardStackMaxY;
var config byte CardStackMaxCards;

// Rank system display preferences
var config bool bShowRankUpMessages;    // Show rank-up broadcast messages from other players
var config bool bShowRankHUD;           // Show the rank HUD element in bottom-left corner
var config int RankPrefsVersion;        // Used to detect first run and set defaults

// Event wave music volume (0.0 = muted, 1.0 = full, default 0.75)
// Set via console: DKMusicVolume 0.5
var config float EventMusicVolume;

// ===================================================================
// GETTERS
// ===================================================================

static function float GetEventMusicVolume()
{
	if (default.EventMusicVolume < 0.0f)
		return 0.0f;
	if (default.EventMusicVolume > 1.0f)
		return 1.0f;
	// First run: config reads 0.0, treat as default
	if (default.EventMusicVolume == 0.0f && default.RankPrefsVersion < 2)
		return 0.75f;

	return default.EventMusicVolume;
}

static function SetEventMusicVolume(float Value)
{
	if (Value < 0.0f)
		Value = 0.0f;
	if (Value > 1.0f)
		Value = 1.0f;

	default.EventMusicVolume = Value;
	static.StaticSaveConfig();
}

static function float GetHudScaleMultiplier()
{
	if (default.HudScaleMultiplier <= 0.0f || default.HudScaleMultiplier > 5.0f)
		return 1.0f;

	return default.HudScaleMultiplier;
}

// Initialize rank preferences on first run (called from DKHudWrapper)
static function InitRankPrefs()
{
	if (default.RankPrefsVersion < 1)
	{
		default.bShowRankUpMessages = True;
		default.bShowRankHUD = True;
		default.RankPrefsVersion = 1;
	}
	if (default.RankPrefsVersion < 2)
	{
		default.EventMusicVolume = 0.75f;
		default.RankPrefsVersion = 2;
	}
	static.StaticSaveConfig();
}

static function bool GetShowRankUpMessages()
{
	return default.bShowRankUpMessages;
}

static function bool GetShowRankHUD()
{
	return default.bShowRankHUD;
}

static function SetShowRankUpMessages(bool bShow)
{
	default.bShowRankUpMessages = bShow;
	static.StaticSaveConfig();
}

static function SetShowRankHUD(bool bShow)
{
	default.bShowRankHUD = bShow;
	static.StaticSaveConfig();
}

static function float GetCardStackMaxY()
{
	if (default.CardStackMaxY <= 0.0f || default.CardStackMaxY > 1.0f)
		return 0.82f;

	return default.CardStackMaxY;
}

static function byte GetCardStackMaxCards()
{
	if (default.CardStackMaxCards < 1 || default.CardStackMaxCards > 10)
		return 4;

	return default.CardStackMaxCards;
}

// ===================================================================
// SETTERS (save to INI immediately)
// ===================================================================

static function SetHudScaleMultiplier(float Value)
{
	if (Value <= 0.0f)
		Value = 1.0f;
	if (Value > 5.0f)
		Value = 5.0f;

	default.HudScaleMultiplier = Value;
	static.StaticSaveConfig();
}

static function SetCardStackMaxY(float Value)
{
	if (Value < 0.3f)
		Value = 0.3f;
	if (Value > 1.0f)
		Value = 1.0f;

	default.CardStackMaxY = Value;
	static.StaticSaveConfig();
}

static function SetCardStackMaxCards(byte Value)
{
	if (Value < 1)
		Value = 1;
	if (Value > 10)
		Value = 10;

	default.CardStackMaxCards = Value;
	static.StaticSaveConfig();
}

defaultproperties
{
	Name="Default__DKConfig_HudPreferences"
}
