// ===================================================================
// DKBulkSync
// ===================================================================
// Wire-format definitions for the chunked-RPC trader/upgrade roster
// sync. Replaces the legacy paged static-array replication path which
// fails silently at scale ("9mm everywhere", empty trader, partial
// data on dedicated servers with large configs).
//
// Architecture:
//   1. Server populates per-roster source arrays (WMGRI.XList[]) during
//      InitGame as before. No change to that population path.
//   2. On each player's PostLogin, DKGameInfo_Endless.PostLogin schedules
//      DKPC.ServerStartBulkSync() with a small delay (~1s for net
//      connection to settle).
//   3. ServerStartBulkSync starts a per-PC timer at BULK_SEND_INTERVAL
//      (0.05s = 20 ticks/sec). Each tick sends ONE chunk for the active
//      roster to that player's client via reliable RPC.
//   4. Client RPC handler appends the chunk's entries to a local recv
//      buffer; when received count == expected total for that roster,
//      DKGRI.IngestXRoster() runs DynamicLoadObject for each path and
//      populates WMGRI.XList[] / TraderItems.SaleItems.
//   5. After all 11 rosters complete, ClientBulkSyncComplete fires and
//      sets bAllDataSynced=True, which unblocks GenerateDataFromSyncData
//      via the existing SyncTimer flow.
//
// Why this works where the legacy path didn't:
//   - Reliable RPC has no silent partial-failure mode. Either the RPC
//     delivers, or the connection drops.
//   - Each chunk carries (StartIdx, TotalCount) so out-of-order or
//     duplicate delivery is impossible to misinterpret.
//   - Server-side pacing eliminates the initial replication burst that
//     stalls reliable channels at large pool sizes.
//   - Truly unbounded: 11 rosters or 11M entries -- same code path.
//   - One pattern per roster. Adding a new roster type = add struct +
//     RPC + ingest function. No more *_C / *_D extension hacks.
//
// Capacity math (per-entry implementation, Option B1):
//   - 1 RPC per entry. Path-only entries: ~150 bytes wire.
//     Larger entries (WeaponUpgrade): ~180 bytes wire.
//   - Pacing: 40 RPCs/sec (1 per 0.025s) * 150B = ~6KB/sec wire.
//     Comfortable margin under per-channel reliable budget.
//   - 5000-entry roster: 5000 RPCs @ 40/sec = ~125 seconds.
//   - Typical 1500-entry total config: ~37 seconds wall clock per join.
//   - One-time cost at PostLogin only; not recurring.
//
// Why per-entry instead of chunks: UE3 reliable RPCs with array<T>
// parameters silently DROP on the wire. Tested with array<struct{...}>,
// array<string>, array<int>, array<byte>, array<float> -- all fail at
// any non-empty payload. Empty-array (TotalCount=0) AND no-arg RPCs
// deliver fine. KF2 vanilla never uses array<> params in reliable RPCs
// for exactly this reason -- confirmed engine limitation. Per-entry
// primitive RPCs are the proven-working pattern.
// ===================================================================
class DKBulkSync extends Object
    abstract;


// ===================================================================
// CONSTANTS
// ===================================================================

/** Pacing constant: time between successive entry RPCs.
 *  0.025s = 40 RPCs/sec/player. Picked to keep total wall-clock time
 *  bounded (~37s for 1500 entries) while leaving the engine room to
 *  drain the per-channel reliable queue between sends. Lower values
 *  (faster sync) risk overflowing the reliable bunch queue. Higher
 *  values are fine but slower.
 *
 *  This is the ONLY pacing knob now -- there's no more chunk size,
 *  because each RPC carries exactly one entry. */
const BULK_SEND_INTERVAL = 0.025f;

/** Total roster count. Bumping this requires a matching enum entry,
 *  struct definition, RPC pair, ingest function, and send-chunk function. */
const BULK_ROSTER_COUNT = 12;


// ===================================================================
// ROSTER ENUM
// ===================================================================
// Stable IDs assigned to each roster type. Used in send-state arrays
// indexed by EBulkRosterID. Order matches the file's declaration order
// of the FBulkXEntry structs.
//
// IMPORTANT: do NOT renumber. ID values are wire-stable and used in
// receive-state arrays in DKPlayerController.
enum EBulkRosterID
{
    BR_AllowedWeapon,         // 0
    BR_TraderWeaponDef,       // 1
    BR_StartingWeapon,        // 2
    BR_PerkUpgrade,           // 3
    BR_SkillUpgrade,          // 4
    BR_WeaponUpgrade,         // 5
    BR_EquipmentUpgrade,      // 6
    BR_Sidearm,               // 7
    BR_Grenade,               // 8
    BR_SpecialWave,           // 9
    BR_ZedBuff,               // 10
    BR_SlotComposition        // 11 -- per-slot upgrade indices + per-weapon counts
};


// ===================================================================
// DTO STRUCTS (wire format — flat primitives only, RPC-safe)
// ===================================================================
// Each struct mirrors the data shape needed by the corresponding decode
// path in DKGameReplicationInfo's existing logic, plus any companion
// data (PerkUpgPrice, bDeluxeSkillUnlock) that lived in parallel arrays.

/** Allowed weapon entry. Maps to AllowedWeaponsList + KFWeaponDefPath
 *  on the GRI/Game. The KFWeapon class path AND the KFWeaponDefinition
 *  path are sent together because they're populated in lockstep server-side. */
struct FBulkAllowedWeaponEntry
{
    var string KFWeaponPath;        // e.g. "ZedternalReborn.WMWeap_Pistol_9mm"
    var int    BuyPrice;
};

/** Trader weapon-definition path. Independent roster from AllowedWeapon
 *  (they exist as separate arrays in the source-of-truth). */
struct FBulkTraderWeaponDefEntry
{
    var string WeapDefPath;         // e.g. "ZedternalReborn.WMWeapDef_9mm"
};

/** Starting weapon (gear given on spawn). */
struct FBulkStartingWeaponEntry
{
    var string KFWeaponPath;
};

/** Perk upgrade. Includes the PerkUpgPrice companion which the legacy
 *  path replicated as a separate parallel int[256] array. */
struct FBulkPerkUpgradeEntry
{
    var string PerkPathName;
    var int    PriceInt;            // -> WMGRI.PerkUpgPrice[idx]
};

/** Skill upgrade. Includes the bDeluxeSkillUnlock companion (was a
 *  parallel byte[256] array in legacy). */
struct FBulkSkillUpgradeEntry
{
    var string SkillPathName;
    var string PerkPathName;
    var byte   bDeluxeUnlock;       // -> WMGRI.bDeluxeSkillUnlock[idx]
};

/** Weapon upgrade definition (the upgrade itself, not per-weapon roll). */
struct FBulkWeaponUpgradeEntry
{
    var string WeaponUpgPathName;
    var int    PriceUnit;
    var float  PriceMultiplier;
    var int    MaxLevel;
    var bool   bIsStatic;
};

/** Equipment upgrade (Armor / Health / etc). */
struct FBulkEquipmentUpgradeEntry
{
    var string EquipmentPathName;
    var int    BasePrice;
    var int    MaxPrice;
    var byte   MaxLevel;
};

/** Sidearm item. */
struct FBulkSidearmEntry
{
    var string WeaponPathName;
    var int    BuyPrice;
};

/** Grenade item. */
struct FBulkGrenadeEntry
{
    var string GrenadePathName;
};

/** Special wave (boss / event wave). */
struct FBulkSpecialWaveEntry
{
    var string SpecialWavePathName;
};

/** ZedBuff (passive zed effects). */
struct FBulkZedBuffEntry
{
    var string ZedBuffPathName;
};


// ===================================================================
// HELPERS
// ===================================================================

/** Safe path-name extraction for a class<X>. Returns empty string if
 *  the class is None, otherwise PathName(Class). Used by the server's
 *  send-side to serialize loaded class<> references back to wire strings. */
static function string SafeClassPath(class<Object> C)
{
    if (C == None)
        return "";
    return PathName(C);
}

// ===================================================================
// SLOT-COMPOSITION BYTE PACKING (roster 11)
// ===================================================================
// The slot composition (per-slot upgrade indices + per-weapon counts) is
// the one roster that is pure bytes rather than path strings. Sending one
// byte per RPC would be ~15500 RPCs (~6 min). Instead we pack SLOT_CHUNK_BYTES
// bytes per RPC as a hex string (2 chars/byte): ~125 RPCs (~3s) for a full
// 15500-byte payload. A single string param is RPC-safe (paths use them);
// only array<> params silently drop, which is why we hex-pack into a string
// rather than send a byte array.

/** Bytes packed into one slot-composition chunk RPC. 128 bytes -> 256-char
 *  hex string, comfortably within reliable-RPC string limits. */
const SLOT_CHUNK_BYTES = 128;

/** Encode one byte (0-255) as two uppercase hex chars. */
static function string ByteToHex2(int b)
{
    local string H;
    H = "0123456789ABCDEF";
    return Mid(H, (b / 16) % 16, 1) $ Mid(H, b % 16, 1);
}

/** Decode one uppercase hex char to its 0-15 value (0 on bad input). */
static function int HexCharToInt(string c)
{
    local int v;
    v = InStr("0123456789ABCDEF", c);
    if (v < 0)
        v = 0;
    return v;
}


defaultproperties
{
    Name="Default__DKBulkSync"
}
