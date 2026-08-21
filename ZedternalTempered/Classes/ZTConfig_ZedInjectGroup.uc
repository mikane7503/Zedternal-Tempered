// ===================================================================
// ZTConfig_ZedInjectGroup - Grouped Random Zed Injection
//
// Adds a GROUPED injection system on top of ZR's existing Zed_WaveGroupInject.
// Entries with the same GroupID are treated as a pool — exactly ONE is picked
// randomly (weighted by Weight) per wave trigger.
//
// This is ideal for random boss spawns at specific waves.
//
// Example INI (KFZedternalUnlimited.ini):
//
//   DK_ZedInjectGroup=(GroupID="Boss10",Wave=10,ZedPath="KFGameContent.KFPawn_ZedPatriarch",Position="END",Count=1,Weight=1.0,MinDiff=0,MaxDiff=4,bRepeat=False)
//   DK_ZedInjectGroup=(GroupID="Boss10",Wave=10,ZedPath="KFGameContent.KFPawn_ZedHans",Position="END",Count=1,Weight=1.0,MinDiff=0,MaxDiff=4,bRepeat=False)
//   DK_ZedInjectGroup=(GroupID="Boss10",Wave=10,ZedPath="KFGameContent.KFPawn_ZedFleshpoundKing",Position="END",Count=1,Weight=1.0,MinDiff=0,MaxDiff=4,bRepeat=False)
//
// On wave 10, exactly ONE of the three bosses is picked randomly (equal weight).
// Set Weight=2.0 on one to make it twice as likely as the others.
//
// bRepeat=True means the group triggers every N waves (e.g. Wave=5 + bRepeat → waves 5, 10, 15...)
// bRepeat=False means the group triggers only on that exact wave number.
//
// Multiple groups with different GroupIDs are independent — each picks one entry.
//
// If no entries are configured, this system does nothing.
// The existing ZR Zed_WaveGroupInject system is completely unaffected.
// ===================================================================
class ZTConfig_ZedInjectGroup extends Object config(ZedternalUnlimited);

struct S_ZedInjectGroupEntry
{
	var string GroupID;
	var int Wave;
	var string ZedPath;
	var string Position;
	var int Count;
	var float Weight;
	var int MinDiff;
	var int MaxDiff;
	var bool bRepeat;

	structdefaultproperties
	{
		Position="END"
		Count=1
		Weight=1.0
		MinDiff=0
		MaxDiff=4
		bRepeat=False
	}
};

var config array<S_ZedInjectGroupEntry> DK_ZedInjectGroup;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		// Empty by default — server owners add entries if they want grouped random injection
		default.DK_ZedInjectGroup.Length = 0;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	local int i;

	for (i = 0; i < default.DK_ZedInjectGroup.Length; ++i)
	{
		if (default.DK_ZedInjectGroup[i].GroupID == "")
		{
			`log("[DK_ZEDINJECT] WARNING: Empty GroupID at index" @ i $ ", removing");
			default.DK_ZedInjectGroup.Remove(i, 1);
			--i;
			continue;
		}
		if (default.DK_ZedInjectGroup[i].ZedPath == "")
		{
			`log("[DK_ZEDINJECT] WARNING: Empty ZedPath at index" @ i $ ", removing");
			default.DK_ZedInjectGroup.Remove(i, 1);
			--i;
			continue;
		}
		if (default.DK_ZedInjectGroup[i].Wave <= 0)
		{
			`log("[DK_ZEDINJECT] WARNING: Wave <= 0 at index" @ i $ ", removing");
			default.DK_ZedInjectGroup.Remove(i, 1);
			--i;
			continue;
		}
		if (default.DK_ZedInjectGroup[i].Count < 1)
			default.DK_ZedInjectGroup[i].Count = 1;
		if (default.DK_ZedInjectGroup[i].Count > 8)
			default.DK_ZedInjectGroup[i].Count = 8;
		if (default.DK_ZedInjectGroup[i].Weight <= 0.0f)
			default.DK_ZedInjectGroup[i].Weight = 1.0f;
		if (default.DK_ZedInjectGroup[i].MinDiff < 0)
			default.DK_ZedInjectGroup[i].MinDiff = 0;
		if (default.DK_ZedInjectGroup[i].MaxDiff > 4)
			default.DK_ZedInjectGroup[i].MaxDiff = 4;
	}

	`log("[DK_ZEDINJECT] Config:" @ default.DK_ZedInjectGroup.Length @ "grouped inject entries");
}

defaultproperties
{
	Name="Default__ZTConfig_ZedInjectGroup"
}
