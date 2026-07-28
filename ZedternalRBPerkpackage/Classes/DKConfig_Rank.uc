// Rank persistence - client-side local INI
// Variable names are intentionally obfuscated to discourage casual INI editing
class DKConfig_Rank extends Object
	config(ZedternalUnlimited_Rank);

// Obfuscated config vars - these names look like engine internals
var config int CacheRenderFrameUID;     // Encoded XP value
var config int NetRelevancySalt;        // Salt for encoding
var config int FrameValidationHash;     // Checksum to detect tampering
var config int ConfigInitFlag;          // Must be 7913 to indicate properly initialized data
var config int SectionRevisionTag;      // Stored reset-epoch counter (compared against CURRENT_RESET_EPOCH)

// Magic constants for encoding
const ENCODE_KEY = 1514045211;      // XOR key for encoding XP
const VALIDATE_KEY = 2116979357;    // XOR key for checksum
const SALT_OFFSET = 48271;          // Added to salt generation

// Reset-epoch counter. Bump this constant to force a one-time hard reset
// of every client's stored rank data on next connection. Each client
// compares its stored SectionRevisionTag against CURRENT_RESET_EPOCH; if
// lower, data is wiped and the new value stamped. Increment on each
// future hard reset (1 -> 2 -> 3 ...).
const CURRENT_RESET_EPOCH = 1;

// Encode raw XP into obfuscated value
static function int EncodeXP(int RawXP, int Salt)
{
	return (RawXP ^ ENCODE_KEY) + Salt;
}

// Decode obfuscated value back to raw XP
static function int DecodeXP(int EncodedXP, int Salt)
{
	return (EncodedXP - Salt) ^ ENCODE_KEY;
}

// Generate checksum from encoded value and salt
static function int GenerateChecksum(int EncodedXP, int Salt)
{
	return (EncodedXP + Salt) ^ VALIDATE_KEY;
}

// Validate stored data - returns True if data is intact
static function bool ValidateData()
{
	local int ExpectedChecksum;

	// ConfigInitFlag must be our magic value to indicate the INI was properly written.
	// Fresh installs have uninitialized memory (garbage) — this catches that.
	if (default.ConfigInitFlag != 7913)
		return False;

	// If all zeros with valid flag, this is a legitimate reset
	if (default.CacheRenderFrameUID == 0 && default.NetRelevancySalt == 0 && default.FrameValidationHash == 0)
		return True;

	ExpectedChecksum = GenerateChecksum(default.CacheRenderFrameUID, default.NetRelevancySalt);
	return (ExpectedChecksum == default.FrameValidationHash);
}

// Get current stored XP (returns 0 if tampered)
static function int GetStoredXP()
{
	local int RawXP;

	// One-time hard reset trigger. Inline (rather than via ResetData)
	// so we can stamp the new SectionRevisionTag in the same
	// StaticSaveConfig pass. Bump CURRENT_RESET_EPOCH to force this for
	// every client on next connection.
	if (default.SectionRevisionTag < CURRENT_RESET_EPOCH)
	{
		`log("[DK_RANK] One-time reset triggered (stored epoch=" $ default.SectionRevisionTag $ " current epoch=" $ CURRENT_RESET_EPOCH $ ")");
		default.CacheRenderFrameUID = 0;
		default.NetRelevancySalt = 0;
		default.FrameValidationHash = 0;
		default.ConfigInitFlag = 7913;
		default.SectionRevisionTag = CURRENT_RESET_EPOCH;
		StaticSaveConfig();
		return 0;
	}

	if (!ValidateData())
	{
		// Data was tampered with - reset to 0
		`log("ZU Rank: Data validation failed. Resetting rank data.");
		ResetData();
		return 0;
	}

	// Fresh install case
	if (default.CacheRenderFrameUID == 0 && default.NetRelevancySalt == 0)
		return 0;

	RawXP = DecodeXP(default.CacheRenderFrameUID, default.NetRelevancySalt);

	// Sanity check - XP should never be negative
	if (RawXP < 0)
	{
		`log("ZU Rank: Decoded negative XP value. Resetting rank data.");
		ResetData();
		return 0;
	}

	return RawXP;
}

// Save XP to config (called on client only)
static function SaveXP(int RawXP)
{
	local int Salt, EncodedXP, Checksum;

	if (RawXP < 0)
		RawXP = 0;

	// Generate a new salt each save for extra obfuscation
	Salt = Rand(2000000000) + SALT_OFFSET;

	EncodedXP = EncodeXP(RawXP, Salt);
	Checksum = GenerateChecksum(EncodedXP, Salt);

	default.CacheRenderFrameUID = EncodedXP;
	default.NetRelevancySalt = Salt;
	default.FrameValidationHash = Checksum;
	default.ConfigInitFlag = 7913;

	StaticSaveConfig();
}

// Add XP and save (convenience function, client only)
static function int AddXP(int Amount)
{
	local int CurrentXP, NewXP, MaxXP;

	CurrentXP = GetStoredXP();
	NewXP = CurrentXP + Amount;

	// Cap at MAX_RANK cumulative XP (~31.3M for rank 500). Previous
	// hardcoded cap of 250000 was a leftover from a 50-rank prototype
	// and stalled all progression at tier 10 (Enforcer).
	MaxXP = class'ZedternalRBPerkpackage.DKRank'.static.GetCumulativeXPForRank(class'ZedternalRBPerkpackage.DKRank'.const.MAX_RANK);
	if (NewXP > MaxXP)
		NewXP = MaxXP;

	SaveXP(NewXP);
	return NewXP;
}

// Reset all rank data
static function ResetData()
{
	default.CacheRenderFrameUID = 0;
	default.NetRelevancySalt = 0;
	default.FrameValidationHash = 0;
	default.ConfigInitFlag = 7913;
	StaticSaveConfig();
}

defaultproperties
{
	Name="Default__DKConfig_Rank"
}
