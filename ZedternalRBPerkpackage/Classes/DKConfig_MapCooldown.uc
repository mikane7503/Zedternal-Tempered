// DKConfig_MapCooldown - Prevents recently played maps from appearing in the vote list
// Server owners configure CooldownCount to control how many map changes before a map returns.
// RecentMaps is auto-managed — do not edit manually.
class DKConfig_MapCooldown extends Object
	config(ZedternalUnlimited);

// Whether the map cooldown system is enabled
var config bool bEnabled;

// Number of map changes before a map can be voted for again
// Example: CooldownCount=3 means after playing a map, 3 other maps must be played first
var config int CooldownCount;

// Auto-managed list of recently played map names (most recent last)
// Do NOT edit this manually — it is updated automatically after each game
var config array<string> RecentMaps;

// Per-map cooldown overrides. Format: MapName=CooldownCount
// Maps not listed here use the default CooldownCount.
// Example:
//   MapCooldownOverride=KF-SteamFortress=5
//   MapCooldownOverride=KF-BioticsLab=1
//   MapCooldownOverride=KF-KillZone_Corridor=0   (0 = no cooldown)
var config array<string> MapCooldownOverride;

var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.bEnabled = True;
		default.CooldownCount = 3;
		default.RecentMaps.Length = 0;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

// Returns true if this is a real map name (not a separator or empty entry).
static function bool IsValidMapName(string MapName)
{
	local int i, Code;
	local bool bHasAlphanumeric;

	if (Len(MapName) == 0)
		return False;

	bHasAlphanumeric = False;
	for (i = 0; i < Len(MapName); ++i)
	{
		Code = Asc(Mid(MapName, i, 1));
		if ((Code >= 65 && Code <= 90) || (Code >= 97 && Code <= 122) || (Code >= 48 && Code <= 57))
		{
			bHasAlphanumeric = True;
			break;
		}
	}

	if (!bHasAlphanumeric)
		return False;

	if (Left(MapName, 4) == "----")
		return False;

	return True;
}

// Sanitize map name for safe INI storage.
// UE3 INI parser chokes on: [ ] = ; # and other special chars.
// Replace anything that isn't alphanumeric, dash, underscore, or dot.
static function string SanitizeMapName(string MapName)
{
	local string Result, Ch;
	local int i, Code;

	Result = "";
	for (i = 0; i < Len(MapName); ++i)
	{
		Ch = Mid(MapName, i, 1);
		Code = Asc(Ch);

		// Allow: A-Z (65-90), a-z (97-122), 0-9 (48-57), - (45), _ (95), . (46)
		if ((Code >= 65 && Code <= 90)
			|| (Code >= 97 && Code <= 122)
			|| (Code >= 48 && Code <= 57)
			|| Code == 45 || Code == 95 || Code == 46)
		{
			Result $= Ch;
		}
		else
		{
			Result $= "_";
		}
	}

	return Result;
}

// Get the cooldown count for a specific map.
// Returns the per-map override if one exists, otherwise the global default.
static function int GetCooldownForMap(string MapName)
{
	local string SafeName, Entry, EntryMap, EntryVal;
	local int i, SplitPos;

	SafeName = SanitizeMapName(MapName);

	for (i = 0; i < default.MapCooldownOverride.Length; ++i)
	{
		Entry = default.MapCooldownOverride[i];
		SplitPos = InStr(Entry, "=");
		if (SplitPos != INDEX_NONE)
		{
			EntryMap = SanitizeMapName(Left(Entry, SplitPos));
			EntryVal = Mid(Entry, SplitPos + 1);
			if (EntryMap ~= SafeName)
				return Max(int(EntryVal), 0);
		}
	}

	return default.CooldownCount;
}

// Call from InitGame after map load. Pushes current map into cooldown list.
static function RegisterCurrentMap(string MapName)
{
	local int i, MaxCooldown;
	local string CleanName;

	if (!default.bEnabled)
		return;

	if (!IsValidMapName(MapName))
		return;

	CleanName = SanitizeMapName(MapName);

	for (i = 0; i < default.RecentMaps.Length; ++i)
	{
		if (default.RecentMaps[i] ~= CleanName)
		{
			default.RecentMaps.Remove(i, 1);
			break;
		}
	}

	default.RecentMaps.AddItem(CleanName);

	// Trim to the LARGEST possible cooldown so per-map overrides work
	MaxCooldown = default.CooldownCount;
	for (i = 0; i < default.MapCooldownOverride.Length; ++i)
	{
		if (InStr(default.MapCooldownOverride[i], "=") != INDEX_NONE)
			MaxCooldown = Max(MaxCooldown, int(Mid(default.MapCooldownOverride[i], InStr(default.MapCooldownOverride[i], "=") + 1)));
	}
	MaxCooldown = Max(MaxCooldown, 1);

	while (default.RecentMaps.Length > MaxCooldown)
		default.RecentMaps.Remove(0, 1);

	static.StaticSaveConfig();
}

// Returns true if this map is on cooldown and should be hidden from vote
static function bool IsMapOnCooldown(string MapName)
{
	local int i, MapCooldown, Position;
	local string SafeName;

	if (!default.bEnabled)
		return False;

	SafeName = SanitizeMapName(MapName);
	MapCooldown = GetCooldownForMap(MapName);

	if (MapCooldown <= 0)
		return False;

	for (i = 0; i < default.RecentMaps.Length; ++i)
	{
		if (default.RecentMaps[i] ~= SafeName)
		{
			Position = default.RecentMaps.Length - i;
			return Position <= MapCooldown;
		}
	}

	return False;
}

// Returns the number of maps currently on cooldown
static function int GetCooldownCount()
{
	return default.RecentMaps.Length;
}

defaultproperties
{
	Name="Default__DKConfig_MapCooldown"
}
