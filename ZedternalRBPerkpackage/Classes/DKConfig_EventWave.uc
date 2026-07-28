class DKConfig_EventWave extends Object
	config(ZedternalUnlimited);

// Master toggle
var config bool bEnabled;

// Probability (0.0-1.0) that any event wave triggers per wave
var config float EventWaveProbability;

// Minimum wave number before event waves can trigger
var config int MinWave;

// Maximum number of event waves per match (0 = unlimited)
var config int MaxPerMatch;

// Per-event weights (higher = more likely when triggered)
// Set to 0 to disable individual events
var config float Weight_Isolation;
var config float Weight_BlackoutPulse;
var config float Weight_VIP;
var config float Weight_HotPotato;
var config float Weight_DeadSilence;
var config float Weight_Highlander;
var config float Weight_RAGE;
var config float Weight_Amogus;
var config float Weight_ChainGang;
var config float Weight_OneInTheChamber;
var config float Weight_Paranoia;
var config float Weight_MarkedForDeath;
var config float Weight_Redacted;
var config float Weight_FogOfWar;
var config float Weight_Nemesis;
var config float Weight_Duel;
var config float Weight_XMen;
var config float Weight_Jitterbug;
var config float Weight_CostumeParty;
var config float Weight_DontBlink;

// Per-event solo disable. When solo (1 living player), events whose flag is
// True are removed from the pool on top of the inherent multiplayer-only
// events (VIP, Hot Potato, etc). Lets harsh-but-soloable events like Blackout
// Pulse, R.A.G.E. or Fog of War be turned off for single-player only.
var config bool SoloDisable_Isolation;
var config bool SoloDisable_BlackoutPulse;
var config bool SoloDisable_DeadSilence;
var config bool SoloDisable_RAGE;
var config bool SoloDisable_OneInTheChamber;
var config bool SoloDisable_Paranoia;
var config bool SoloDisable_Redacted;
var config bool SoloDisable_FogOfWar;
var config bool SoloDisable_Nemesis;
var config bool SoloDisable_XMen;
var config bool SoloDisable_Jitterbug;
var config bool SoloDisable_CostumeParty;
var config bool SoloDisable_DontBlink;

var config int MODEVERSION;

// ===================================================================
// LOCALIZED EVENT NAMES + DESCRIPTIONS
// Loaded from [DKConfig_EventWave] section of active locale .int / .kor.
// Accessed via default.VarName so static lookup functions get the value
// from the Class Default Object (CDO), which the engine populates at
// startup with the player's locale.
// ===================================================================
var localized string EventName_None;
var localized string EventName_Isolation;
var localized string EventName_BlackoutPulse;
var localized string EventName_VIP;
var localized string EventName_HotPotato;
var localized string EventName_DeadSilence;
var localized string EventName_Highlander;
var localized string EventName_RAGE;
var localized string EventName_Amogus;
var localized string EventName_ChainGang;
var localized string EventName_OneInTheChamber;
var localized string EventName_Paranoia;
var localized string EventName_MarkedForDeath;
var localized string EventName_Redacted;
var localized string EventName_FogOfWar;
var localized string EventName_Nemesis;
var localized string EventName_Duel;
var localized string EventName_ToMeMyXMen;
var localized string EventName_Jitterbug;
var localized string EventName_CostumeParty;
var localized string EventName_DontBlink;

var localized string EventDesc_Isolation;
var localized string EventDesc_BlackoutPulse;
var localized string EventDesc_VIP;
var localized string EventDesc_HotPotato;
var localized string EventDesc_DeadSilence;
var localized string EventDesc_Highlander;
var localized string EventDesc_RAGE;
var localized string EventDesc_Amogus;
var localized string EventDesc_ChainGang;
var localized string EventDesc_OneInTheChamber;
var localized string EventDesc_Paranoia;
var localized string EventDesc_MarkedForDeath;
var localized string EventDesc_Redacted;
var localized string EventDesc_FogOfWar;
var localized string EventDesc_Nemesis;
var localized string EventDesc_Duel;
var localized string EventDesc_ToMeMyXMen;
var localized string EventDesc_Jitterbug;
var localized string EventDesc_CostumeParty;
var localized string EventDesc_DontBlink;

const NUM_EVENTS = 26;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.bEnabled = True;
		default.EventWaveProbability = 0.15f;
		default.MinWave = 3;
		default.MaxPerMatch = 0;

		default.Weight_Isolation = 0.5f;
		default.Weight_BlackoutPulse = 0.8f;
		default.Weight_VIP = 0.5f;
		default.Weight_HotPotato = 0.6f;
		default.Weight_DeadSilence = 0.0f;
		default.Weight_Highlander = 0.4f;
		default.Weight_RAGE = 0.7f;
		default.Weight_Amogus = 0.3f;
		default.Weight_ChainGang = 0.4f;
		default.Weight_OneInTheChamber = 0.5f;
		default.Weight_Paranoia = 0.6f;
		default.Weight_MarkedForDeath = 0.5f;
		default.Weight_Redacted = 0.5f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 2)
	{
		default.Weight_FogOfWar = 0.6f;
		default.Weight_Nemesis = 0.7f;
		default.Weight_Duel = 0.4f;

		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 3)
	{
		default.Weight_XMen = 0.5f;

		default.MODEVERSION = 3;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 4)
	{
		// Solo disables default off -> no behavior change until configured.
		default.SoloDisable_Isolation = False;
		default.SoloDisable_BlackoutPulse = False;
		default.SoloDisable_DeadSilence = False;
		default.SoloDisable_RAGE = False;
		default.SoloDisable_OneInTheChamber = False;
		default.SoloDisable_Paranoia = False;
		default.SoloDisable_Redacted = False;
		default.SoloDisable_FogOfWar = False;
		default.SoloDisable_Nemesis = False;
		default.SoloDisable_XMen = False;

		default.MODEVERSION = 4;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 5)
	{
		default.Weight_Jitterbug = 0.6f;
		default.Weight_CostumeParty = 0.5f;
		default.Weight_DontBlink = 0.7f;

		default.SoloDisable_Jitterbug = False;
		default.SoloDisable_CostumeParty = False;
		default.SoloDisable_DontBlink = False;

		default.MODEVERSION = 5;
		static.StaticSaveConfig();
	}
}

static function CheckBasicConfigValues()
{
	default.EventWaveProbability = FClamp(default.EventWaveProbability, 0.f, 1.f);
	if (default.MinWave < 1) default.MinWave = 1;

	`log("[DK_EVENTWAVE] Config: bEnabled=" $ default.bEnabled
		@ "Prob=" $ default.EventWaveProbability
		@ "MinWave=" $ default.MinWave
		@ "MaxPerMatch=" $ default.MaxPerMatch);
}

static function byte RollEventWave(int WaveNum, int EventsTriggeredThisMatch, int PlayerCount)
{
	local float TotalWeight, Roll, Cumulative;
	local float Weights[26];
	local int i;

	if (!default.bEnabled)
		return 0;

	if (WaveNum < default.MinWave)
		return 0;

	if (default.MaxPerMatch > 0 && EventsTriggeredThisMatch >= default.MaxPerMatch)
		return 0;

	if (FRand() > default.EventWaveProbability)
		return 0;

	Weights[0] = 0.f;
	Weights[1] = 0.f;
	Weights[2] = 0.f;
	Weights[3] = 0.f;
	Weights[4] = 0.f;
	Weights[5] = 0.f;
	Weights[6] = default.Weight_Isolation;
	Weights[7] = default.Weight_BlackoutPulse;
	Weights[8] = default.Weight_VIP;
	Weights[9] = default.Weight_HotPotato;
	Weights[10] = default.Weight_DeadSilence;
	Weights[11] = default.Weight_Highlander;
	Weights[12] = default.Weight_RAGE;
	Weights[13] = default.Weight_Amogus;
	Weights[14] = default.Weight_ChainGang;
	Weights[15] = default.Weight_OneInTheChamber;
	Weights[16] = default.Weight_Paranoia;
	Weights[17] = default.Weight_MarkedForDeath;
	Weights[18] = default.Weight_Redacted;
	Weights[19] = default.Weight_FogOfWar;
	Weights[20] = default.Weight_Nemesis;
	Weights[21] = default.Weight_Duel;
	Weights[22] = default.Weight_XMen;
	Weights[23] = default.Weight_Jitterbug;
	Weights[24] = default.Weight_CostumeParty;
	Weights[25] = default.Weight_DontBlink;

	// Filter out multiplayer-only events when solo
	if (PlayerCount <= 1)
	{
		for (i = 0; i < NUM_EVENTS; ++i)
		{
			if (NeedsMultiplePlayers(byte(i + 1)) || IsDisabledInSolo(byte(i + 1)))
				Weights[i] = 0.f;
		}
	}

	TotalWeight = 0.f;
	for (i = 0; i < NUM_EVENTS; ++i)
	{
		if (Weights[i] < 0.f) Weights[i] = 0.f;
		TotalWeight += Weights[i];
	}

	if (TotalWeight <= 0.f)
		return 0;

	Roll = FRand() * TotalWeight;
	Cumulative = 0.f;

	for (i = 0; i < NUM_EVENTS; ++i)
	{
		if (Weights[i] > 0.f)
		{
			Cumulative += Weights[i];
			if (Roll < Cumulative)
				return byte(i + 1);
		}
	}

	return byte(NUM_EVENTS);
}

// Public accessor: returns the localized event name, falling back to hardcoded
// English when the .int [DKConfig_EventWave] section lacks an entry (e.g. newly
// added events not yet in the loc file). Without the fallback the event-wave
// banner draws a blank name + no icon and reads as "nothing happened".
static function string GetEventName(byte EventID)
{
	local string S;

	S = GetLocalizedEventName(EventID);
	if (S == "")
		S = GetEventNameFallback(EventID);
	return S;
}

static function string GetEventNameFallback(byte EventID)
{
	switch (EventID)
	{
		case 24: return "Jitterbug";
		case 25: return "Costume Party";
		case 26: return "Don't Blink";
		default: return "";
	}
}

static function string GetLocalizedEventName(byte EventID)
{
	switch (EventID)
	{
		case 7:  return default.EventName_Isolation;
		case 8:  return default.EventName_BlackoutPulse;
		case 9:  return default.EventName_VIP;
		case 10: return default.EventName_HotPotato;
		case 11: return default.EventName_DeadSilence;
		case 12: return default.EventName_Highlander;
		case 13: return default.EventName_RAGE;
		case 14: return default.EventName_Amogus;
		case 15: return default.EventName_ChainGang;
		case 16: return default.EventName_OneInTheChamber;
		case 17: return default.EventName_Paranoia;
		case 18: return default.EventName_MarkedForDeath;
		case 19: return default.EventName_Redacted;
		case 20: return default.EventName_FogOfWar;
		case 21: return default.EventName_Nemesis;
		case 22: return default.EventName_Duel;
		case 23: return default.EventName_ToMeMyXMen;
		case 24: return default.EventName_Jitterbug;
		case 25: return default.EventName_CostumeParty;
		case 26: return default.EventName_DontBlink;
		default: return default.EventName_None;
	}
}

static function byte GetEventIDFromName(string EventName)
{
	EventName = Caps(EventName);
	if (EventName == "ISOLATION") return 7;
	if (EventName == "BLACKOUTPULSE" || EventName == "BLACKOUT" || EventName == "PULSE") return 8;
	if (EventName == "VIP") return 9;
	if (EventName == "HOTPOTATO" || EventName == "HOT_POTATO" || EventName == "POTATO") return 10;
	if (EventName == "DEADSILENCE" || EventName == "DEAD_SILENCE" || EventName == "SILENCE") return 11;
	if (EventName == "HIGHLANDER") return 12;
	if (EventName == "RAGE" || EventName == "R.A.G.E.") return 13;
	if (EventName == "AMOGUS") return 14;
	if (EventName == "CHAINGANG" || EventName == "CHAIN_GANG" || EventName == "CHAIN") return 15;
	if (EventName == "ONEINTHECHAMBER" || EventName == "OITC" || EventName == "CHAMBER") return 16;
	if (EventName == "PARANOIA") return 17;
	if (EventName == "MARKEDFORDEATH" || EventName == "MARKED" || EventName == "MFD") return 18;
	if (EventName == "REDACTED") return 19;
	if (EventName == "FOGOFWAR" || EventName == "FOG" || EventName == "FOW") return 20;
	if (EventName == "NEMESIS") return 21;
	if (EventName == "DUEL") return 22;
	if (EventName == "XMEN" || EventName == "X-MEN" || EventName == "TOMEYMYXMEN") return 23;
	if (EventName == "JITTERBUG" || EventName == "JITTER") return 24;
	if (EventName == "COSTUMEPARTY" || EventName == "COSTUME" || EventName == "FREAKSHOW") return 25;
	if (EventName == "DONTBLINK" || EventName == "DONT_BLINK" || EventName == "BLINK" || EventName == "ANGELS") return 26;
	return 0;
}

// Returns the registered sound ID name for an event
static function name GetEventSoundID(byte EventID)
{
	switch (EventID)
	{
		case 7: return 'EventWave_Isolation';
		case 8: return 'EventWave_BlackoutPulse';
		case 9: return 'EventWave_VIP';
		case 10: return 'EventWave_HotPotato';
		case 11: return 'EventWave_DeadSilence';
		case 12: return 'EventWave_Highlander';
		case 13: return 'EventWave_RAGE';
		case 14: return 'EventWave_Amogus';
		case 15: return 'EventWave_ChainGang';
		case 16: return 'EventWave_OneInTheChamber';
		case 17: return 'EventWave_Paranoia';
		case 18: return 'EventWave_MarkedForDeath';
		case 19: return 'EventWave_Redacted';
		case 20: return 'EventWave_FogOfWar';
		case 21: return 'EventWave_Nemesis';
		case 22: return 'EventWave_Duel';
		case 23: return 'EventWave_XMen';
		case 24: return 'EventWave_Jitterbug';
		case 25: return 'EventWave_CostumeParty';
		case 26: return 'EventWave_DontBlink';
		default: return '';
	}
}

static function string GetEventDescription(byte EventID)
{
	local string S;

	S = GetLocalizedEventDescription(EventID);
	if (S == "")
		S = GetEventDescriptionFallback(EventID);
	return S;
}

static function string GetEventDescriptionFallback(byte EventID)
{
	switch (EventID)
	{
		case 24: return "Every zed moves at a random speed";
		case 25: return "Zeds appear at random sizes (cosmetic only)";
		case 26: return "Zeds freeze while you look at them, and lunge the moment you look away";
		default: return "";
	}
}

static function string GetLocalizedEventDescription(byte EventID)
{
	switch (EventID)
	{
		case 7:  return default.EventDesc_Isolation;
		case 8:  return default.EventDesc_BlackoutPulse;
		case 9:  return default.EventDesc_VIP;
		case 10: return default.EventDesc_HotPotato;
		case 11: return default.EventDesc_DeadSilence;
		case 12: return default.EventDesc_Highlander;
		case 13: return default.EventDesc_RAGE;
		case 14: return default.EventDesc_Amogus;
		case 15: return default.EventDesc_ChainGang;
		case 16: return default.EventDesc_OneInTheChamber;
		case 17: return default.EventDesc_Paranoia;
		case 18: return default.EventDesc_MarkedForDeath;
		case 19: return default.EventDesc_Redacted;
		case 20: return default.EventDesc_FogOfWar;
		case 21: return default.EventDesc_Nemesis;
		case 22: return default.EventDesc_Duel;
		case 23: return default.EventDesc_ToMeMyXMen;
		case 24: return default.EventDesc_Jitterbug;
		case 25: return default.EventDesc_CostumeParty;
		case 26: return default.EventDesc_DontBlink;
		default: return "";
	}
}

// Returns true if this event requires the DKEventWaveManager
static function bool NeedsManager(byte EventID)
{
	switch (EventID)
	{
		case 7: return True;   // Isolation
		case 8: return True;   // Blackout Pulse
		case 9: return True;   // VIP
		case 10: return True;  // Hot Potato
		case 12: return True;  // Highlander
		case 13: return True;  // R.A.G.E.
		case 14: return True;  // Amogus
		case 15: return True;  // Chain Gang
		case 16: return True;  // One in the Chamber
		case 17: return True;  // Paranoia
		case 18: return True;  // Marked for Death
		case 19: return True;  // Redacted
		case 20: return True;  // Fog of War
		case 21: return True;  // Nemesis
		case 22: return True;  // Duel
		case 23: return True;  // X-Men
		case 24: return True;  // Jitterbug (needs OnZedSpawned dispatch)
		case 25: return True;  // Costume Party (needs OnZedSpawned dispatch)
		case 26: return True;  // Don't Blink (gaze loop + OnZedSpawned)
		default: return False;
	}
}

// Returns true if this event requires 2+ players and should be
// excluded from the pool when playing solo
static function bool NeedsMultiplePlayers(byte EventID)
{
	switch (EventID)
	{
		case 9: return True;   // VIP
		case 10: return True;  // Hot Potato
		case 12: return True;  // Highlander
		case 14: return True;  // Amogus
		case 15: return True;  // Chain Gang
		case 18: return True;  // Marked for Death
		case 22: return True;  // Duel
		default: return False;
	}
}

// Returns true if this event is configured to be skipped when playing solo.
// Applied on top of NeedsMultiplePlayers in the RollEventWave solo filter.
static function bool IsDisabledInSolo(byte EventID)
{
	switch (EventID)
	{
		case 7:  return default.SoloDisable_Isolation;
		case 8:  return default.SoloDisable_BlackoutPulse;
		case 11: return default.SoloDisable_DeadSilence;
		case 13: return default.SoloDisable_RAGE;
		case 16: return default.SoloDisable_OneInTheChamber;
		case 17: return default.SoloDisable_Paranoia;
		case 19: return default.SoloDisable_Redacted;
		case 20: return default.SoloDisable_FogOfWar;
		case 21: return default.SoloDisable_Nemesis;
		case 23: return default.SoloDisable_XMen;
		case 24: return default.SoloDisable_Jitterbug;
		case 25: return default.SoloDisable_CostumeParty;
		case 26: return default.SoloDisable_DontBlink;
		default: return False;
	}
}

defaultproperties
{
	Name="Default__DKConfig_EventWave"
}
