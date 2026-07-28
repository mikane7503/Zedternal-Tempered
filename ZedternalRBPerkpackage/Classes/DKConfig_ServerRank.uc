// ===================================================================
// DKConfig_ServerRank - Server-side local rank storage
//
// When RankMode=1 (Local), XP is stored per-player on the server.
// Players on different servers have independent rank progression.
// Format: PlayerID=XP (SteamID64=TotalXP)
//
// Saved to KFZedternalUnlimited_ServerRanks.ini
// ===================================================================
class DKConfig_ServerRank extends Object
	config(ZedternalUnlimited);

var config array<string> ServerRankData;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ServerRankData.Length = 0;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}

	// MODEVERSION 2: one-time hard reset of all stored player XP.
	// Triggered after fixing the 250000 XP cap that stalled players at
	// tier 10 (Enforcer). Wipes the per-SteamID XP table once on first
	// boot of the new build; subsequent boots no-op. Bump to 3 next time
	// a server-side wipe is needed.
	if (default.MODEVERSION < 2)
	{
		`log("[DK_RANK] Server rank one-time reset (MODEVERSION 1 -> 2): wiping" @ default.ServerRankData.Length @ "stored player entries");
		default.ServerRankData.Length = 0;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
}

// Get stored XP for a player by SteamID string
static function int GetPlayerXP(string PlayerID)
{
	local int i, SplitPos;
	local string Entry, EntryID, EntryXP;

	for (i = 0; i < default.ServerRankData.Length; ++i)
	{
		Entry = default.ServerRankData[i];
		SplitPos = InStr(Entry, "=");
		if (SplitPos != INDEX_NONE)
		{
			EntryID = Left(Entry, SplitPos);
			if (EntryID == PlayerID)
			{
				EntryXP = Mid(Entry, SplitPos + 1);
				return Max(int(EntryXP), 0);
			}
		}
	}

	return 0;
}

// Set stored XP for a player by SteamID string
static function SetPlayerXP(string PlayerID, int XP)
{
	local int i, SplitPos, MaxXP;
	local string Entry, EntryID;

	if (XP < 0) XP = 0;
	// Cap at MAX_RANK cumulative XP (~31.3M for rank 500). Previous
	// hardcoded cap of 250000 was a leftover from a 50-rank prototype.
	MaxXP = class'ZedternalRBPerkpackage.DKRank'.static.GetCumulativeXPForRank(class'ZedternalRBPerkpackage.DKRank'.const.MAX_RANK);
	if (XP > MaxXP) XP = MaxXP;

	// Find existing entry and update
	for (i = 0; i < default.ServerRankData.Length; ++i)
	{
		Entry = default.ServerRankData[i];
		SplitPos = InStr(Entry, "=");
		if (SplitPos != INDEX_NONE)
		{
			EntryID = Left(Entry, SplitPos);
			if (EntryID == PlayerID)
			{
				default.ServerRankData[i] = PlayerID $ "=" $ string(XP);
				static.StaticSaveConfig();
				return;
			}
		}
	}

	// New player — add entry
	default.ServerRankData.AddItem(PlayerID $ "=" $ string(XP));
	static.StaticSaveConfig();
}

// Add XP for a player and return new total
static function int AddPlayerXP(string PlayerID, int Amount)
{
	local int CurrentXP, NewXP, MaxXP;

	CurrentXP = GetPlayerXP(PlayerID);
	MaxXP = class'ZedternalRBPerkpackage.DKRank'.static.GetCumulativeXPForRank(class'ZedternalRBPerkpackage.DKRank'.const.MAX_RANK);
	NewXP = Min(CurrentXP + Amount, MaxXP);
	SetPlayerXP(PlayerID, NewXP);
	return NewXP;
}

// Get rank for a player
static function byte GetPlayerRank(string PlayerID)
{
	return class'ZedternalRBPerkpackage.DKRank'.static.GetRankFromXP(GetPlayerXP(PlayerID));
}

// Extract SteamID string from a PlayerReplicationInfo
static function string GetSteamIDFromPRI(PlayerReplicationInfo PRI)
{
	if (PRI == None)
		return "";

	return PRI.UniqueId.Uid.A $ PRI.UniqueId.Uid.B;
}

defaultproperties
{
	Name="Default__DKConfig_ServerRank"
}
