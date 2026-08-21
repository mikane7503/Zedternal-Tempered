// ===================================================================
// ZTConfig_Gravity - World Gravity Configuration
//
// Set gravity globally or per-map in KFZedternalReborn_Game.ini
//
// Default KF2 gravity: -1150 (negative = downward)
// Lower values (e.g. -600) = moon gravity
// Higher values (e.g. -2000) = heavy gravity
// 0 = use default (no override)
//
// Per-map entries override the global value for that map.
// Map names are case-insensitive and should NOT include file extension.
// Example: "KF-BioticsLab" not "KF-BioticsLab.kfm"
//
// INI example:
//   [ZedternalTempered.ZTConfig_Gravity]
//   Gravity_Global=0
//   Gravity_MapOverrides=(MapName="KF-Moonbase",Gravity=-400)
//   Gravity_MapOverrides=(MapName="KF-Nuked",Gravity=-800)
// ===================================================================
class ZTConfig_Gravity extends Object config(ZedternalUnlimited);

struct S_GravityMapOverride
{
	var string MapName;
	var float Gravity;
};

var config float Gravity_Global;
var config array<S_GravityMapOverride> Gravity_MapOverrides;
var config int MODEVERSION;

static function InitializeConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Gravity_Global = 0.0f;
		default.Gravity_MapOverrides.Length = 0;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Gravity_Global = 0.0f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i;

	if (default.Gravity_Global > 0.0f)
	{
		`log("[DK_GRAVITY] WARNING: Gravity_Global is positive (" $ default.Gravity_Global $ "), gravity should be negative. Setting to 0 (default).");
		default.Gravity_Global = 0.0f;
	}

	for (i = 0; i < default.Gravity_MapOverrides.Length; ++i)
	{
		if (default.Gravity_MapOverrides[i].MapName == "")
		{
			`log("[DK_GRAVITY] WARNING: Empty MapName in Gravity_MapOverrides at index" @ i $ ", removing");
			default.Gravity_MapOverrides.Remove(i, 1);
			--i;
			continue;
		}
		if (default.Gravity_MapOverrides[i].Gravity > 0.0f)
		{
			`log("[DK_GRAVITY] WARNING: Positive gravity for" @ default.Gravity_MapOverrides[i].MapName $ ", gravity should be negative. Setting to 0 (default).");
			default.Gravity_MapOverrides[i].Gravity = 0.0f;
		}
	}

	`log("[DK_GRAVITY] Config: Global=" $ default.Gravity_Global @ "MapOverrides=" $ default.Gravity_MapOverrides.Length);
}

// Returns the gravity to apply for the current map, or 0 if no override
static function float GetGravityForMap(string MapName)
{
	local int i;
	local string CurrentMap;

	// Strip path prefix if present (WorldInfo.GetMapName() may include prefix)
	CurrentMap = MapName;
	i = InStr(CurrentMap, "-");
	if (i == INDEX_NONE)
	{
		// Try stripping everything before last path separator
		i = InStr(CurrentMap, "/");
		if (i != INDEX_NONE)
			CurrentMap = Mid(CurrentMap, i + 1);
	}

	// Check per-map overrides first
	for (i = 0; i < default.Gravity_MapOverrides.Length; ++i)
	{
		if (default.Gravity_MapOverrides[i].MapName ~= MapName
			|| default.Gravity_MapOverrides[i].MapName ~= CurrentMap)
		{
			return default.Gravity_MapOverrides[i].Gravity;
		}
	}

	// Fall back to global
	return default.Gravity_Global;
}

defaultproperties
{
	Name="Default__ZTConfig_Gravity"
}
