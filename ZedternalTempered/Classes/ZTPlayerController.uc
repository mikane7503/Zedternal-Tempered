// ===================================================================
// ZTPlayerController - Handles active ability system via console commands
// UPDATED: Uses ZTGFxScoreBoardWrapper as HUD class
// UPDATED: Added ClientPlayChronoshiftSound for custom sound replication
// UPDATED: Added ClientPlayAchievementSound and ClientPlayPerkUnlockSound
// UPDATED: Added automatic keybinding system on first join
// UPDATED: Added ClientPlayWraithFormSound for Haunted perk ability
// UPDATED: Added Roguelike Upgrade System with Flash UI
// ===================================================================
class ZTPlayerController extends WMPlayerController;

// Track active ability helpers for this player
struct AbilitySlotData
{
    var Info Helper;
    var string AbilityName;
    var class<Info> HelperClass;
    var Texture2D AbilityIcon;
};

var array<AbilitySlotData> AbilitySlots;

// Keybinding system
var bool bHasCheckedKeybindings;

// Rank system
var int PendingRankXP;
var int CachedClientRank;
var int ValidatedMaxRank;  // Server-side: highest rank validated via checksum (anti-cheat ceiling)

// Persists across pawn death/respawn so Haunted cannot fire twice in one wave.
var int LastHauntedDisasterWave;

// Menu references
var ZTUpgradeSelectMenu UpgradeSelectMenu;
var ZTCommandWheelMovie CommandWheelMovie;
var ZTDomainWheelMovie DomainWheelMovie;
var ZTPossessorWheelMovie PossessorWheelMovie;

// PUPPET MASTER SPIKE (throwaway debug) - refs held server-side while puppeting
var KFPawn_Human   PuppetSavedHuman;
var KFPawn_Monster PuppetZed;
var bool           bPuppetRevertPending;   // set by GameInfo.ReduceDamage on a lethal hit
var Weapon         PuppetSavedWeapon;       // human's held weapon, restored on revert
var bool           bClientPuppetCam;        // client: drive third-person while puppeting a living zed
var int            PuppetWeaponRepairTries; // client: retry counter for the weapon-proxy repair
var bool           bPuppetContentKicked;    // client: ensure ClientGivenTo content-load kick fires once

// ===================================================================
// ROGUELIKE UPGRADE SELECTION SYSTEM
// ===================================================================

// Pending upgrade options (client-side storage)
struct PendingRoguelikeOption
{
    var string UpgradeID;
    var string DisplayName;
    var string Description;
    var string IconPath;
    var int Rarity;
    var string AccumulatedDisplay;  // Pre-formatted accumulated bonus text (e.g. "+50 HP")
};

var array<PendingRoguelikeOption> PendingUpgradeOptions;
var bool bRoguelikeSelectionActive;

// Event wave music system
var AudioComponent EventMusicComponent;

// X-Men power display (set by server, drawn by HUD)
var string XMenPowerName;
var string XMenPowerDesc;

// ===================================================================
// BULK SYNC SYSTEM ? STRUCT + VAR DECLARATIONS
// ===================================================================
// Implementation (RPCs, send/receive logic, timers) lives at the bottom
// of this file. All declarations must be at the top of the class because
// UnrealScript does not allow struct or var declarations after function
// bodies. See ZTBulkSync.uc for architecture overview.

// ---------------------------------------------------------------------
// DTO STRUCTS (wire format)
// ---------------------------------------------------------------------

struct FBulkAllowedWeaponEntry
{
    var string KFWeaponPath;
    var int    BuyPrice;
};

struct FBulkTraderWeaponDefEntry
{
    var string WeapDefPath;
};

struct FBulkStartingWeaponEntry
{
    var string KFWeaponPath;
};

struct FBulkPerkUpgradeEntry
{
    var string PerkPathName;
    var int    PriceInt;
};

struct FBulkSkillUpgradeEntry
{
    var string SkillPathName;
    var string PerkPathName;
    var byte   bDeluxeUnlock;
};

struct FBulkWeaponUpgradeEntry
{
    var string WeaponUpgPathName;
    var int    PriceUnit;
    var float  PriceMultiplier;
    var int    MaxLevel;
    var bool   bIsStatic;
};

struct FBulkEquipmentUpgradeEntry
{
    var string EquipmentPathName;
    var int    BasePrice;
    var int    MaxPrice;
    var byte   MaxLevel;
};

struct FBulkSidearmEntry
{
    var string WeaponPathName;
    var int    BuyPrice;
};

struct FBulkGrenadeEntry
{
    var string GrenadePathName;
};

struct FBulkSpecialWaveEntry
{
    var string SpecialWavePathName;
};

struct FBulkZedBuffEntry
{
    var string ZedBuffPathName;
};

// ---------------------------------------------------------------------
// CLIENT-SIDE RECEIVE STATE
// ---------------------------------------------------------------------
// One dynamic buffer per roster. Pre-sized to TotalCount on first chunk
// receipt so out-of-order chunks (shouldn't happen on reliable RPC, but
// defensive) write to the correct slots.

var array<FBulkAllowedWeaponEntry>      RecvBuf_AllowedWeapon;
var array<FBulkTraderWeaponDefEntry>    RecvBuf_TraderWeaponDef;
var array<FBulkStartingWeaponEntry>     RecvBuf_StartingWeapon;
var array<FBulkPerkUpgradeEntry>        RecvBuf_PerkUpgrade;
var array<FBulkSkillUpgradeEntry>       RecvBuf_SkillUpgrade;
var array<FBulkWeaponUpgradeEntry>      RecvBuf_WeaponUpgrade;
var array<FBulkEquipmentUpgradeEntry>   RecvBuf_EquipmentUpgrade;
var array<FBulkSidearmEntry>            RecvBuf_Sidearm;
var array<FBulkGrenadeEntry>            RecvBuf_Grenade;
var array<FBulkSpecialWaveEntry>        RecvBuf_SpecialWave;
var array<FBulkZedBuffEntry>            RecvBuf_ZedBuff;

// Per-roster expected total (set when first chunk arrives) and received
// count. When ReceivedCount == ExpectedTotal, that roster is complete.
// Indexed by EBulkRosterID (0..11).
// NOTE: byte (not bool) because UnrealScript forbids fixed-size bool arrays.
var int  BulkRecvExpected[12];
var int  BulkRecvReceived[12];
var byte BulkRecvComplete[12];

// True after ALL 12 rosters have completed AND been ingested into GRI.
var bool BulkRecvAllDone;

// ---------------------------------------------------------------------
// SERVER-SIDE SEND STATE
// ---------------------------------------------------------------------
// Cached references to data sources, captured at ServerStartBulkSync time.

var WMGameReplicationInfo BulkSendGRI;
var WMGameInfo_Endless    BulkSendGI;

// Per-roster send progress. SendNextIdx[i] = next entry index to send.
// NOTE: byte (not bool) because UnrealScript forbids fixed-size bool arrays.
var int  BulkSendNextIdx[12];
var byte BulkSendComplete[12];

// True after all 12 rosters have been fully transmitted.
var bool BulkSendAllDone;

// ===================================================================
// INITIALIZATION
// ===================================================================

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();
    
    // Initialize client-side artwork preference config
    class'ZTConfig_LocalArtwork'.static.InitializeConfig();

    // Start keybinding check ONLY on the owning client
    if (Role < ROLE_Authority || WorldInfo.NetMode == NM_Standalone)
        SetTimer(2.0f, false, nameof(CheckAndApplyDefaultKeybindings));
}

// Alternative hook - this runs on client when PlayerController is fully ready
simulated event ReceivedPlayer()
{
    Super.ReceivedPlayer();
    
    // Ensure keybinding check happens on client
    if (!bHasCheckedKeybindings)
        SetTimer(2.0f, false, nameof(CheckAndApplyDefaultKeybindings));

    // Initialize rank system - client reads local INI and reports to server
    ClientInitRank();
}

// ===================================================================
// RANK SYSTEM
// ===================================================================

// Client reads stored rank from local INI and reports encoded data to server
reliable client function ClientInitRank()
{
    local int StoredXP;

    StoredXP = class'ZedternalTempered.ZTConfig_Rank'.static.GetStoredXP();
    CachedClientRank = class'ZedternalTempered.ZTRank'.static.GetRankFromXP(StoredXP);

    // Send the full encoded triplet so the server can validate independently
    ServerReportRankData(
        class'ZTConfig_Rank'.default.CacheRenderFrameUID,
        class'ZTConfig_Rank'.default.NetRelevancySalt,
        class'ZTConfig_Rank'.default.FrameValidationHash
    );
}

// Server receives encoded rank data, validates checksum, decodes XP, computes rank
reliable server function ServerReportRankData(int EncodedXP, int Salt, int Checksum)
{
    local int ExpectedChecksum, RawXP;
    local int ComputedRank;

    // Fresh install: all zeros = rank 0
    if (EncodedXP == 0 && Salt == 0 && Checksum == 0)
    {
        ServerApplyRank(0);
        return;
    }

    // Validate checksum server-side
    ExpectedChecksum = class'ZTConfig_Rank'.static.GenerateChecksum(EncodedXP, Salt);
    if (ExpectedChecksum != Checksum)
    {
        `log("[DK_RANK] REJECTED rank data from" @ PlayerReplicationInfo.PlayerName @ "- checksum mismatch (tampering detected)");
        ServerApplyRank(0);
        return;
    }

    // Decode XP server-side
    RawXP = class'ZTConfig_Rank'.static.DecodeXP(EncodedXP, Salt);

    // Sanity check
    if (RawXP < 0 || RawXP > 35000000)
    {
        `log("[DK_RANK] REJECTED rank data from" @ PlayerReplicationInfo.PlayerName @ "- XP out of range:" @ RawXP);
        ServerApplyRank(0);
        return;
    }

    ComputedRank = class'ZedternalTempered.ZTRank'.static.GetRankFromXP(RawXP);
    `log("[DK_RANK] Validated rank for" @ PlayerReplicationInfo.PlayerName @ "- XP:" @ RawXP @ "Rank:" @ ComputedRank);
    ServerApplyRank(ComputedRank);
}

// Legacy: still accept byte rank for backwards compat (e.g. ZUSetXP re-report)
// but cap at current validated rank to prevent escalation
reliable server function ServerReportRank(int RankLevel)
{
    local ZTPlayerReplicationInfo DKPRI;
    local string SteamID;
    local int LocalXP;

    DKPRI = ZTPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKPRI == None)
        return;

    // If rank is disabled on this server, always set rank to 0
    if (!class'ZTConfig_RankSettings'.static.IsRankEnabled())
    {
        DKPRI.PlayerRank = 0;
        return;
    }

    // In local rank mode, ignore the client's reported rank and use server storage
    if (class'ZTConfig_RankSettings'.static.IsLocalRank())
    {
        SteamID = class'ZTConfig_ServerRank'.static.GetSteamIDFromPRI(PlayerReplicationInfo);
        if (SteamID != "")
        {
            LocalXP = class'ZTConfig_ServerRank'.static.GetPlayerXP(SteamID);
            DKPRI.PlayerRank = class'ZedternalTempered.ZTRank'.static.GetRankFromXP(LocalXP);
        }
        else
            DKPRI.PlayerRank = 0;

        EnforceRankGatedPerks(DKPRI);
        return;
    }

    // Global rank mode: cap at validated rank to prevent escalation
    // ServerReportRankData sets ValidatedMaxRank via checksum verification.
    // This path is only used by ZUSetXP/FlushRankXP re-reports.
    if (ValidatedMaxRank > 0 && RankLevel > ValidatedMaxRank)
    {
        `log("[DK_RANK] Capped ServerReportRank from" @ RankLevel @ "to validated max" @ ValidatedMaxRank @ "for" @ DKPRI.PlayerName);
        RankLevel = ValidatedMaxRank;
    }

    DKPRI.PlayerRank = Min(RankLevel, class'ZedternalTempered.ZTRank'.const.MAX_RANK);
    EnforceRankGatedPerks(DKPRI);
}

// Core rank application - used by both ServerReportRankData and ServerReportRank
function ServerApplyRank(int RankLevel)
{
    local ZTPlayerReplicationInfo DKPRI;
    local string SteamID;
    local int LocalXP;

    DKPRI = ZTPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKPRI == None)
        return;

    if (!class'ZTConfig_RankSettings'.static.IsRankEnabled())
    {
        DKPRI.PlayerRank = 0;
        return;
    }

    // In local rank mode, ignore client data entirely
    if (class'ZTConfig_RankSettings'.static.IsLocalRank())
    {
        SteamID = class'ZTConfig_ServerRank'.static.GetSteamIDFromPRI(PlayerReplicationInfo);
        if (SteamID != "")
        {
            LocalXP = class'ZTConfig_ServerRank'.static.GetPlayerXP(SteamID);
            DKPRI.PlayerRank = class'ZedternalTempered.ZTRank'.static.GetRankFromXP(LocalXP);
        }
        else
            DKPRI.PlayerRank = 0;

        EnforceRankGatedPerks(DKPRI);
        return;
    }

    // Global rank mode - set validated ceiling and apply
    ValidatedMaxRank = RankLevel;
    DKPRI.PlayerRank = Min(RankLevel, class'ZedternalTempered.ZTRank'.const.MAX_RANK);
    EnforceRankGatedPerks(DKPRI);
}

// Enforce rank-gated perk locks AND unlocks based on the player's actual rank.
// Called from ServerReportRank every time rank changes (initial report, ZUSetXP, wave XP).
// Locks perks the player doesn't qualify for, unlocks ones they do.
function EnforceRankGatedPerks(ZTPlayerReplicationInfo DKPRI)
{
    local WMGameReplicationInfo WMGRI;
    local int i;
    local string PerkClassName;
    local int GlobalRank;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None || DKPRI == None)
        return;

    GlobalRank = DKPRI.PlayerRank;

    for (i = 0; i < WMGRI.PerkUpgradesList.Length; ++i)
    {
        PerkClassName = string(WMGRI.PerkUpgradesList[i].PerkUpgrade.Name);

        // Only touch perks that have a rank requirement
        if (class'ZTConfig_PerkUnlockRules'.static.GetRankRequirement(PerkClassName) <= 0)
            continue;

        // If player does NOT meet the rank requirement, lock the perk
        if (!class'ZTConfig_PerkUnlockRules'.static.MeetsRankRequirement(PerkClassName, GlobalRank, 0))
        {
            if (DKPRI.IsPerkUnlocked(i))
            {
                DKPRI.SetPerkUnlocked(i, False);
                `log("[DK_RANKPERK] Locked rank-gated perk:" @ PerkClassName @ "for" @ DKPRI.PlayerName
                    @ "(Rank" @ GlobalRank @ "< Required" @ class'ZTConfig_PerkUnlockRules'.static.GetRankRequirement(PerkClassName) $ ")");
            }
        }
        // If player DOES meet the requirement but perk is locked, unlock it
        else if (!DKPRI.IsPerkUnlocked(i))
        {
            DKPRI.SetPerkUnlocked(i, True);
            `log("[DK_RANKPERK] Unlocked rank-gated perk:" @ PerkClassName @ "for" @ DKPRI.PlayerName
                @ "(Rank" @ GlobalRank @ ">= Required" @ class'ZTConfig_PerkUnlockRules'.static.GetRankRequirement(PerkClassName) $ ")");
        }
    }
}

// Server awards XP during wave (accumulated, not sent immediately)
function AddRankXP(int Amount)
{
    PendingRankXP += Amount;
}

// Server flushes accumulated XP to client at wave end
function FlushRankXP()
{
    local string SteamID;
    local int NewXP;
    local int NewRank;
    local ZTPlayerReplicationInfo DKPRI;

    if (PendingRankXP <= 0 || !class'ZTConfig_RankSettings'.static.IsRankEnabled())
    {
        PendingRankXP = 0;
        return;
    }

    if (class'ZTConfig_RankSettings'.static.IsLocalRank())
    {
        // Local rank mode: server stores XP and updates PRI directly
        SteamID = class'ZTConfig_ServerRank'.static.GetSteamIDFromPRI(PlayerReplicationInfo);
        if (SteamID != "")
        {
            NewXP = class'ZTConfig_ServerRank'.static.AddPlayerXP(SteamID, PendingRankXP);
            NewRank = class'ZedternalTempered.ZTRank'.static.GetRankFromXP(NewXP);

            DKPRI = ZTPlayerReplicationInfo(PlayerReplicationInfo);
            if (DKPRI != None)
                DKPRI.PlayerRank = NewRank;
        }
        // Still send to client so their HUD progress bar updates
        ClientReceiveRankXP(PendingRankXP);
        PendingRankXP = 0;
    }
    else
    {
        // Global rank mode: client stores XP locally
        // Raise the validated ceiling so legitimate rank-ups from this XP aren't capped.
        // Server authorized this XP, so any resulting rank increase is legitimate.
        if (ValidatedMaxRank < class'ZedternalTempered.ZTRank'.const.MAX_RANK)
            ValidatedMaxRank = Min(ValidatedMaxRank + 1, class'ZedternalTempered.ZTRank'.const.MAX_RANK);

        ClientReceiveRankXP(PendingRankXP);
        PendingRankXP = 0;
    }
}

// Debug: Check rank status in console with "ZURank"
exec function ZURank()
{
    local int StoredXP;
    local int MyRank;
    local ZTPlayerReplicationInfo DKPRI;

    StoredXP = class'ZedternalTempered.ZTConfig_Rank'.static.GetStoredXP();
    MyRank = class'ZedternalTempered.ZTRank'.static.GetRankFromXP(StoredXP);

    ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZURankHeader'));
    ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZURankStoredXP', string(StoredXP)));
    ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZURankRank', string(MyRank), class'ZedternalTempered.ZTRank'.static.GetTierDisplayName(MyRank)));
    ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZURankCachedClientRank', string(CachedClientRank)));
    ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZURankPendingXP', string(PendingRankXP)));

    DKPRI = ZTPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKPRI != None)
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZURankPRIRank', string(DKPRI.PlayerRank)));
    else
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZURankPRIError'));

    ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZURankNextAt', string(class'ZedternalTempered.ZTRank'.static.GetCumulativeXPForRank(MyRank + 1))));
}

// Debug: Set rank XP manually with "ZUSetXP <amount>"
exec function ZUSetXP(int Amount)
{
    class'ZedternalTempered.ZTConfig_Rank'.static.SaveXP(Amount);
    ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZUSetXPDone', string(Amount)));
    ClientInitRank();
}

// Toggle rank-up broadcast messages from other players
exec function ZTRankMessages()
{
    local bool bCurrent;
    bCurrent = class'ZTConfig_HudPreferences'.static.GetShowRankUpMessages();
    class'ZTConfig_HudPreferences'.static.SetShowRankUpMessages(!bCurrent);
    if (!bCurrent)
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('RankMessagesOn'));
    else
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('RankMessagesOff'));
}

// Toggle rank HUD element visibility
exec function ZTRankHUD()
{
    local bool bCurrent;
    bCurrent = class'ZTConfig_HudPreferences'.static.GetShowRankHUD();
    class'ZTConfig_HudPreferences'.static.SetShowRankHUD(!bCurrent);
    if (!bCurrent)
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('RankHUDOn'));
    else
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('RankHUDOff'));
}

exec function DKMusicVolume(optional float Volume = -1.0f)
{
    // No args = show current volume
    if (Volume < 0.0f)
    {
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('MusicVolumeCurrent', string(int(class'ZTConfig_HudPreferences'.static.GetEventMusicVolume() * 100.0f))));
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('MusicVolumeUsage'));
        return;
    }

    class'ZTConfig_HudPreferences'.static.SetEventMusicVolume(Volume);
    ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('MusicVolumeSet', string(int(class'ZTConfig_HudPreferences'.static.GetEventMusicVolume() * 100.0f))));

    // Apply immediately to active music
    if (EventMusicComponent != None)
    {
        EventMusicComponent.VolumeMultiplier = class'ZTConfig_HudPreferences'.static.GetEventMusicVolume();
    }
}

// ===================================================================
// EVENT WAVE FORCE COMMAND
// Usage: ZUEvent isolation / blackout / vip / rage / fog / nemesis / duel / etc.
//        ZUEvent           (no args = show current state)
//        ZUEvent clear     (cancel forced event)
// Forces the specified event wave on the NEXT wave start.
// ===================================================================

exec function ZUEvent(optional string EventName)
{
    if (EventName == "")
    {
        // Show current state ? runs client-side, localizes locally
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZUEventHeader'));
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZUEventSensoryList'));
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZUEventGameplayList1'));
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZUEventGameplayList2'));
        ClientMessage(class'ZTMessageManager'.static.LocalizeMessage('ZUEventUsage'));
        return;
    }

    ServerForceEventWave(EventName);
}

reliable server function ServerForceEventWave(string EventName)
{
    local byte EventID;
    local ZTGameInfo_Endless GI;
    local ZTGameInfo_Endless_AllWeapons GIAW;

    if (Caps(EventName) == "CLEAR" || Caps(EventName) == "NONE" || Caps(EventName) == "OFF")
    {
        GIAW = ZTGameInfo_Endless_AllWeapons(WorldInfo.Game);
        if (GIAW != None)
            GIAW.ForcedEventWaveID = 0;
        else
        {
            GI = ZTGameInfo_Endless(WorldInfo.Game);
            if (GI != None)
                GI.ForcedEventWaveID = 0;
        }
        // Server-side function ? route via ClientLocalizedChat so the
        // string is formatted using the CLIENT's active locale
        ClientLocalizedChat('EventWaveCleared');
        return;
    }

    EventID = class'ZTConfig_EventWave'.static.GetEventIDFromName(EventName);
    if (EventID == 0)
    {
        ClientLocalizedChat('EventWaveUnknown', EventName);
        return;
    }

    GIAW = ZTGameInfo_Endless_AllWeapons(WorldInfo.Game);
    if (GIAW != None)
        GIAW.ForcedEventWaveID = EventID;
    else
    {
        GI = ZTGameInfo_Endless(WorldInfo.Game);
        if (GI != None)
            GI.ForcedEventWaveID = EventID;
    }

    ClientLocalizedChat('EventWaveSet', class'ZTConfig_EventWave'.static.GetEventName(EventID));
}

// Server sends accumulated XP to client for local INI saving
reliable client function ClientReceiveRankXP(int XPAmount)
{
    local int NewTotalXP;
    local int OldRank, NewRank;

    OldRank = CachedClientRank;
    NewTotalXP = class'ZedternalTempered.ZTConfig_Rank'.static.AddXP(XPAmount);
    NewRank = class'ZedternalTempered.ZTRank'.static.GetRankFromXP(NewTotalXP);

    // If rank changed, update server so PRI replicates to all clients
    if (NewRank != OldRank)
    {
        CachedClientRank = NewRank;
        ServerReportRank(NewRank);
        ServerBroadcastRankUp(NewRank);
    }
}

// Client tells server to announce rank-up to all players
reliable server function ServerBroadcastRankUp(int NewRank)
{
    local ZTPlayerController DKPC;
    local string PlayerName;

    // Check if server allows rank-up broadcasts
    if (!class'ZTConfig_RankSettings'.static.IsRankUpBroadcastEnabled())
        return;

    PlayerName = PlayerReplicationInfo != None ? PlayerReplicationInfo.PlayerName : "Unknown";

    // Send to all players on the server
    foreach WorldInfo.AllControllers(class'ZTPlayerController', DKPC)
    {
        // Phase 4 localization: send rank as INT instead of pre-formatted string
        // so each receiving client formats the rank in its own active locale.
        if (DKPC == self)
            DKPC.ClientReceiveRankUpMessage('RankUpSelf', "", NewRank, True);
        else
            DKPC.ClientReceiveRankUpMessage('RankUpOther', PlayerName, NewRank, False);
    }
}

// Client receives rank-up announcement. Takes a localization key + the
// rank as an int + the (other) player's name; the formatted rank string
// and final message are built using THIS client's active locale, so each
// player sees their own language regardless of what the server uses.
reliable client function ClientReceiveRankUpMessage(name MessageKey, string PlayerName, int NewRank, bool bIsSelf)
{
    local ZTHudWrapper CustomHUD;
    local Color MsgColor;
    local string Message, RankString;

    // Self messages always show; other player messages respect the preference
    if (!bIsSelf && !class'ZTConfig_HudPreferences'.static.GetShowRankUpMessages())
        return;

    // Format rank using THIS client's active locale
    RankString = class'ZedternalTempered.ZTRank'.static.GetRankDisplayString(NewRank);

    // Localize the message template, substituting locale-formatted args
    if (bIsSelf)
        Message = class'ZTMessageManager'.static.LocalizeMessage(MessageKey, RankString, "");
    else
        Message = class'ZTMessageManager'.static.LocalizeMessage(MessageKey, PlayerName, RankString);

    // Gold color for rank-up messages
    MsgColor.R = 255;
    MsgColor.G = 215;
    MsgColor.B = 0;
    MsgColor.A = 255;

    CustomHUD = class'ZTHudWrapper'.static.GetReaperHUD(self);
    if (CustomHUD != None)
        CustomHUD.AddNotificationMessage(Message, MsgColor, 1);
    else
        ClientMessage(Message, 'Event');
}

// Send a localized chat message from the server to a client. Wire format
// sends only the message key + args; the client looks up its own active
// locale and formats. Used by server-side functions like ServerForceEventWave.
reliable client function ClientLocalizedChat(name MessageKey, optional string Arg1, optional string Arg2)
{
    local string Message;
    Message = class'ZTMessageManager'.static.LocalizeMessage(MessageKey, Arg1, Arg2);
    ClientMessage(Message, 'Event');
}

// ===================================================================
// SHAPESHIFTER POPUP RPCs
// Server sends buff index(es) + helper-formatted English desc strings.
// Client builds the popup using its own locale (localized buff names
// + localized stat suffixes from ZTHudWrapper).
// ===================================================================

// Mimicry stack gained (Rank 20+ accumulating buff). Sends buff index +
// the helper's pre-formatted desc string + current stack count.
reliable client function ClientShapeshifterMimicryGain(int BuffIndex, string OriginalDesc, int StackCount)
{
    local ZTHudWrapper HUD;
    local string Message;

    HUD = ZTHudWrapper(MyHud);
    if (HUD == None)
        return;

    Message = HUD.FormatShapeshifterMimicryGain(BuffIndex, OriginalDesc, StackCount);
    class'ZTMessageManager'.static.SendImportant(self, Message);
}

// Shapeshifted (rolled new buff at wave start). Buff2Idx == -1 means single buff.
reliable client function ClientShapeshifterTransform(int Buff1Idx, string Desc1, int Buff2Idx, string Desc2)
{
    local ZTHudWrapper HUD;
    local string Message;

    HUD = ZTHudWrapper(MyHud);
    if (HUD == None)
        return;

    Message = HUD.FormatShapeshifterTransform(Buff1Idx, Desc1, Buff2Idx, Desc2);
    class'ZTMessageManager'.static.SendImportant(self, Message);
}

// ===================================================================
// GAMBIT POPUP RPCs
// Server sends GambitIndex + computed values (Target, SecondaryParam,
// pre-formatted reward percentages); client builds the popup using its
// own locale via ZTHudWrapper.FormatGambit* helpers.
// ===================================================================

// New Gambit activated at wave start. Sends rarity, gambit index, computed
// target, and the gambit's secondary param (for descriptions that use %s).
reliable client function ClientGambitStart(byte Rarity, byte GambitIndex, int Target, int SecondaryParam)
{
    local ZTHudWrapper HUD;
    local string Message;

    HUD = ZTHudWrapper(MyHud);
    if (HUD == None)
        return;

    Message = HUD.FormatGambitStartPopup(Rarity, GambitIndex, Target, SecondaryParam);
    class'ZTMessageManager'.static.SendCritical(self, Message);
}

// Gambit auto-completed at wave end (succeeded).
reliable client function ClientGambitAutoComplete(byte GambitIndex)
{
    local ZTHudWrapper HUD;
    local string Message;

    HUD = ZTHudWrapper(MyHud);
    if (HUD == None)
        return;

    Message = HUD.FormatGambitAutoComplete(GambitIndex);
    class'ZTMessageManager'.static.SendCritical(self, Message);
}

// Gambit expired at wave end (failed).
reliable client function ClientGambitExpired(byte GambitIndex)
{
    local ZTHudWrapper HUD;
    local string Message;

    HUD = ZTHudWrapper(MyHud);
    if (HUD == None)
        return;

    Message = HUD.FormatGambitExpired(GambitIndex);
    class'ZTMessageManager'.static.SendImportant(self, Message);
}

// Gambit completed mid-wave (objective met before wave end).
reliable client function ClientGambitMidWaveComplete(byte GambitIndex)
{
    local ZTHudWrapper HUD;
    local string Message;

    HUD = ZTHudWrapper(MyHud);
    if (HUD == None)
        return;

    Message = HUD.FormatGambitMidWaveComplete(GambitIndex);
    class'ZTMessageManager'.static.SendCritical(self, Message);
}

// Reward granted after a Gambit completes. Server sends pre-formatted percentage
// strings (e.g. "+5.0%") so the client only has to substitute localized component
// labels. Empty string for a component means it wasn't awarded.
reliable client function ClientGambitReward(string DamagePctFmt, int DoshAmount, string SpeedPctFmt, int CardSharkDosh, int CardSharkStacks)
{
    local ZTHudWrapper HUD;
    local string Message;

    HUD = ZTHudWrapper(MyHud);
    if (HUD == None)
        return;

    Message = HUD.FormatGambitReward(DamagePctFmt, DoshAmount, SpeedPctFmt, CardSharkDosh, CardSharkStacks);
    class'ZTMessageManager'.static.SendCritical(self, Message);
}

// ===================================================================
// ROGUELIKE UPGRADE SELECTION - CLIENT FUNCTIONS
// ===================================================================

// Called by server to start upgrade selection (clears previous options)
reliable client function ClientReceiveUpgradeSelectionStart()
{
    `log("[DK_ROGUELIKE_UI] ClientReceiveUpgradeSelectionStart - clearing pending options");
    
    PendingUpgradeOptions.Length = 0;
    bRoguelikeSelectionActive = false;
}

// Called by server to send an upgrade option
reliable client function ClientReceiveUpgradeOption(int OptionIndex, string UpgradeID, string DisplayName, string Description, string IconPath, int Rarity, string AccumulatedDisplay)
{
    local PendingRoguelikeOption NewOption;
    
    `log("[DK_ROGUELIKE_UI] ClientReceiveUpgradeOption:" 
        @ "Index=" $ OptionIndex 
        @ "ID=" $ UpgradeID 
        @ "Name=" $ DisplayName 
        @ "Rarity=" $ Rarity
        @ "Accumulated=" $ AccumulatedDisplay);
    
    NewOption.UpgradeID = UpgradeID;
    NewOption.DisplayName = DisplayName;
    NewOption.Description = Description;
    NewOption.IconPath = IconPath;
    NewOption.Rarity = Rarity;
    NewOption.AccumulatedDisplay = AccumulatedDisplay;
    
    // Ensure array is big enough
    while (PendingUpgradeOptions.Length <= OptionIndex)
    {
        PendingUpgradeOptions.AddItem(NewOption);
    }
    
    PendingUpgradeOptions[OptionIndex] = NewOption;
}

// Called by server to show the upgrade selection UI
reliable client function ClientShowUpgradeSelection()
{
    `log("[DK_ROGUELIKE_UI] ClientShowUpgradeSelection - showing Flash UI with " $ PendingUpgradeOptions.Length $ " options");
    
    bRoguelikeSelectionActive = true;
    
    // Open Flash menu
    OpenUpgradeSelectMenu();
}

// Called by server to hide the upgrade selection UI
reliable client function ClientHideUpgradeSelection()
{
    `log("[DK_ROGUELIKE_UI] ClientHideUpgradeSelection - hiding Flash UI");
    
    bRoguelikeSelectionActive = false;
    PendingUpgradeOptions.Length = 0;
    
    // Close Flash menu
    CloseUpgradeSelectMenu();
}

// ===================================================================
// ROGUELIKE UPGRADE SELECTION - FLASH MENU
// ===================================================================

function OpenUpgradeSelectMenu()
{
    local array<string> UpgradeIDs;
    local array<string> AccumulatedDisplays;
    local int i;
    
    `log("[DK_ROGUELIKE_UI] OpenUpgradeSelectMenu called");
    
    // Build upgrade IDs and accumulated display arrays from pending options
    for (i = 0; i < PendingUpgradeOptions.Length; i++)
    {
        UpgradeIDs.AddItem(PendingUpgradeOptions[i].UpgradeID);
        AccumulatedDisplays.AddItem(PendingUpgradeOptions[i].AccumulatedDisplay);
        `log("[DK_ROGUELIKE_UI]   Option " $ i $ ": " $ PendingUpgradeOptions[i].UpgradeID @ "Accumulated:" @ PendingUpgradeOptions[i].AccumulatedDisplay);
    }
    
    // IMPORTANT: Always destroy and recreate the menu to ensure proper input capture
    // GFxMoviePlayer doesn't properly reinitialize input after Close() + Start()
    if (UpgradeSelectMenu != None)
    {
        UpgradeSelectMenu.Close();
        UpgradeSelectMenu = None;
        `log("[DK_ROGUELIKE_UI] Destroyed previous menu instance");
    }
    
    // Create fresh menu
    UpgradeSelectMenu = new class'ZTUpgradeSelectMenu';
    UpgradeSelectMenu.Init(LocalPlayer(Player));
    `log("[DK_ROGUELIKE_UI] Created new ZTUpgradeSelectMenu");
    
    // Open menu and set options with accumulated bonus data
    UpgradeSelectMenu.OpenMenu(self);
    UpgradeSelectMenu.SetUpgradeOptions(UpgradeIDs, AccumulatedDisplays);
    
    `log("[DK_ROGUELIKE_UI] Upgrade select menu opened with " $ PendingUpgradeOptions.Length $ " options");
}

function CloseUpgradeSelectMenu()
{
    if (UpgradeSelectMenu != None && UpgradeSelectMenu.bMenuOpen)
    {
        UpgradeSelectMenu.CloseMenu();
        `log("[DK_ROGUELIKE_UI] Upgrade select menu closed");
    }
}

// ===================================================================
// ROGUELIKE UPGRADE SELECTION - SERVER FUNCTIONS
// ===================================================================

// Server RPC: Player selected an upgrade
reliable server function ServerSelectRoguelikeUpgrade(int OptionIndex)
{
    local ZTGameInfo_Endless DKGI;
    local ZTGameInfo_Endless_AllWeapons DKGI_AW;
    
    `log("[DK_ROGUELIKE] ServerSelectRoguelikeUpgrade: OptionIndex=" $ OptionIndex $ " from " $ PlayerReplicationInfo.PlayerName);
    
    // Try standard mode first
    DKGI = ZTGameInfo_Endless(WorldInfo.Game);
    if (DKGI != None && DKGI.RoguelikeManager != None)
    {
        DKGI.RoguelikeManager.OnPlayerSelectedUpgrade(self, OptionIndex);
        return;
    }
    
    // Try AllWeapons mode
    DKGI_AW = ZTGameInfo_Endless_AllWeapons(WorldInfo.Game);
    if (DKGI_AW != None && DKGI_AW.RoguelikeManager != None)
    {
        DKGI_AW.RoguelikeManager.OnPlayerSelectedUpgrade(self, OptionIndex);
        return;
    }
    
    `log("[DK_ROGUELIKE] ERROR: Could not find RoguelikeManager! Game class: " $ WorldInfo.Game.Class);
}

// ===================================================================
// DELUXE SKILL UPGRADE (on-demand dosh sink, ZTConfig_DeluxeUpgrade)
// Converts an already owned, non-Deluxe skill into its Deluxe version for
// a fee, gated by the owning perk's level. Targeted = a specific skill;
// Random = a random eligible non-Deluxe owned skill in the given perk.
// ===================================================================
reliable server function ServerBuyDeluxeUpgrade(int SkillIndex)
{
    local ZTGameReplicationInfo DKGRI;
    local ZTPlayerReplicationInfo DKPRI;

    DKGRI = ZTGameReplicationInfo(WorldInfo.GRI);
    DKPRI = ZTPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKGRI == None || DKPRI == None || !DKGRI.bDeluxeUpgradeEnabled)
        return;

    if (IsDeluxeSkillEligible(DKGRI, DKPRI, SkillIndex))
        ApplyDeluxeUpgrade(DKGRI, DKPRI, SkillIndex);
}

reliable server function ServerBuyDeluxeUpgradeRandom(int PerkIndex)
{
    local ZTGameReplicationInfo DKGRI;
    local ZTPlayerReplicationInfo DKPRI;
    local array<int> Eligible;
    local int i;
    local string PerkPath;

    DKGRI = ZTGameReplicationInfo(WorldInfo.GRI);
    DKPRI = ZTPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKGRI == None || DKPRI == None || !DKGRI.bDeluxeUpgradeEnabled)
        return;
    if (PerkIndex < 0 || PerkIndex >= DKGRI.PerkUpgradesList.Length)
        return;
    if (DKPRI.GetPerkLevel(PerkIndex) < DKGRI.DeluxeMinPerkLevel)
        return;

    PerkPath = PathName(DKGRI.PerkUpgradesList[PerkIndex].PerkUpgrade);

    for (i = 0; i < DKGRI.SkillUpgradesList.Length; ++i)
    {
        if (DKGRI.SkillUpgradesList[i].PerkPathName ~= PerkPath
            && DKPRI.GetSkillUpgrade(i) == 1)
        {
            Eligible.AddItem(i);
        }
    }

    if (Eligible.Length == 0)
        return;

    ApplyDeluxeUpgrade(DKGRI, DKPRI, Eligible[Rand(Eligible.Length)]);
}

// Targeted-path validation: skill owned + not already Deluxe, and its owning
// perk meets the configured level gate.
function bool IsDeluxeSkillEligible(ZTGameReplicationInfo DKGRI, ZTPlayerReplicationInfo DKPRI, int SkillIndex)
{
    local int i, PerkIdx;
    local string PerkPath;

    if (SkillIndex < 0 || SkillIndex >= DKGRI.SkillUpgradesList.Length)
        return False;
    if (DKPRI.GetSkillUpgrade(SkillIndex) != 1)   // 1 = owned, not Deluxe
        return False;

    PerkPath = DKGRI.SkillUpgradesList[SkillIndex].PerkPathName;
    PerkIdx = INDEX_NONE;
    for (i = 0; i < DKGRI.PerkUpgradesList.Length; ++i)
    {
        if (PathName(DKGRI.PerkUpgradesList[i].PerkUpgrade) ~= PerkPath)
        {
            PerkIdx = i;
            break;
        }
    }
    if (PerkIdx == INDEX_NONE)
        return False;

    return DKPRI.GetPerkLevel(PerkIdx) >= DKGRI.DeluxeMinPerkLevel;
}

// Charge dosh and flip the skill to Deluxe. The effect re-applies through the
// live Modify*Passive hooks (same mechanism a normal skill buy uses); there is
// no explicit apply call to mirror, and the removal hooks are deliberately not
// used (calling DeleteHelperClass with no apply-counterpart could strip a
// helper that would not respawn).
function ApplyDeluxeUpgrade(ZTGameReplicationInfo DKGRI, ZTPlayerReplicationInfo DKPRI, int SkillIndex)
{
    if (DKPRI.Score < DKGRI.DeluxeUpgradeCost)
        return;

    DKPRI.UnlockSkillUpgrade(SkillIndex, True);   // already owned; this sets bDeluxe

    // Charge the cost in ALL netmodes. ApplyDeluxeUpgrade only ever runs
    // server-side (called from the ServerBuyDeluxeUpgrade RPCs), so NetMode is
    // never NM_Client here. Gating the deduction on NM_DedicatedServer meant
    // standalone/listen hosts were never charged -> Deluxe upgrades were free in
    // solo while working correctly in dedicated MP (reported bug).
    DKPRI.AddDosh(-DKGRI.DeluxeUpgradeCost);
    DKPRI.SyncTrigger = !DKPRI.SyncTrigger;

    UpdateWeaponMagAndCap();
    DKPRI.RecalculatePlayerLevel();
    DKPRI.bForceNetUpdate = True;
}

// Debug console command for selecting upgrade (backup/testing)
exec function SelectUpgrade(int OptionNum)
{
    if (!bRoguelikeSelectionActive)
    {
        ClientMessage("No upgrade selection active!");
        return;
    }
    
    if (OptionNum < 1 || OptionNum > PendingUpgradeOptions.Length)
    {
        ClientMessage("Invalid option! Choose 1-" $ PendingUpgradeOptions.Length);
        return;
    }
    
    `log("[DK_ROGUELIKE_UI] Player selected option " $ OptionNum $ " via console command");
    
    // Close menu if open
    CloseUpgradeSelectMenu();
    
    // Send selection to server
    ServerSelectRoguelikeUpgrade(OptionNum - 1);
    
    // Clear local state
    bRoguelikeSelectionActive = false;
    ClientMessage("Selection sent to server...");
}

// ===================================================================
// AUTOMATIC KEYBINDING SYSTEM
// ===================================================================

simulated function CheckAndApplyDefaultKeybindings()
{
    local ZT_Config_Keybindings KeyConfig;
    
    // Only run on the client that owns this controller
    if (Role == ROLE_Authority)
    {
        `log("ZTPlayerController: CheckAndApplyDefaultKeybindings called on SERVER - skipping");
        return;
    }
    
    if (bHasCheckedKeybindings)
    {
        `log("ZTPlayerController [CLIENT]: Already checked keybindings");
        return;
    }
        
    bHasCheckedKeybindings = true;
    
    `log("ZTPlayerController [CLIENT]: Starting keybinding check...");
    
    // Load the config
    KeyConfig = new class'ZT_Config_Keybindings';
    
    // Initialize defaults if config is empty
    class'ZT_Config_Keybindings'.static.InitializeDefaults(KeyConfig);
    
    `log("ZTPlayerController [CLIENT]: Config loaded, bHasAppliedDefaults =" @ KeyConfig.bHasAppliedDefaults);
    
    // Check if we've already applied defaults for this user
    if (!KeyConfig.bHasAppliedDefaults)
    {
        `log("ZTPlayerController [CLIENT]: First time - applying default keybindings...");
        
        ApplyDefaultKeybindings(KeyConfig);
        
        // Mark as applied and save to user's config
        KeyConfig.bHasAppliedDefaults = true;
        KeyConfig.SaveConfig();
        
        `log("ZTPlayerController [CLIENT]: Saved config with bHasAppliedDefaults = true");
        
        // Show welcome message with keybind info
        ClientMessage("===============================================");
        ClientMessage("   Zedternal RB Perkpackage Installed");
        ClientMessage("===============================================");
        ClientMessage("  F1 - Open Upgrade Menu");
        ClientMessage("  F2/F3/F4/F5 - Activate Abilities");
        ClientMessage("  Type: DKShowKeybinds for full list");
        ClientMessage("  Type: DKResetKeybinds to reset bindings");
        ClientMessage("===============================================");
    }
    else
    {
        `log("ZTPlayerController [CLIENT]: Keybindings already applied previously - skipping");
    }

    // Always-run pass: bind any default whose key is currently UNBOUND. This
    // fills in newly-added default binds (e.g. the Hyde serum key) for users
    // who installed before the bind existed -- bHasAppliedDefaults is already
    // true for them, so the first-time path above never re-runs. Only touches
    // genuinely-unbound keys, so it never clobbers user customizations.
    ApplyMissingKeybindings(KeyConfig);
}

simulated function ApplyMissingKeybindings(ZT_Config_Keybindings KeyConfig)
{
    local int i;
    local string BindCommand;

    for (i = 0; i < KeyConfig.DefaultKeybindings.Length; i++)
    {
        if (!IsKeyBound(KeyConfig.DefaultKeybindings[i].KeyName))
        {
            BindCommand = "SetBind" @ KeyConfig.DefaultKeybindings[i].KeyName @ KeyConfig.DefaultKeybindings[i].Command;
            ConsoleCommand(BindCommand);
            `log("ZTPlayerController [CLIENT]: Filled missing keybind -" @ KeyConfig.DefaultKeybindings[i].KeyName @ "=" @ KeyConfig.DefaultKeybindings[i].Command);
        }
    }
}

// True if KeyName is currently bound to any (non-empty) command.
simulated function bool IsKeyBound(string KeyName)
{
    local PlayerInput PlayerInputRef;
    local int i;

    PlayerInputRef = PlayerInput;
    if (PlayerInputRef == None)
        return false;

    for (i = 0; i < PlayerInputRef.Bindings.Length; i++)
    {
        if (PlayerInputRef.Bindings[i].Name == name(KeyName)
            && PlayerInputRef.Bindings[i].Command != "")
            return true;
    }

    return false;
}

simulated function ApplyDefaultKeybindings(ZT_Config_Keybindings KeyConfig)
{
    local int i;
    local string BindCommand;
    local int SuccessCount;
    
    SuccessCount = 0;
    
    `log("ZTPlayerController [CLIENT]: Starting to apply default keybindings...");
    
    for (i = 0; i < KeyConfig.DefaultKeybindings.Length; i++)
    {
        // Check if this key is already bound to something critical
        if (!ShouldOverrideKey(KeyConfig.DefaultKeybindings[i].KeyName))
        {
            BindCommand = "SetBind" @ KeyConfig.DefaultKeybindings[i].KeyName @ KeyConfig.DefaultKeybindings[i].Command;
            ConsoleCommand(BindCommand);
            SuccessCount++;
            
            `log("ZTPlayerController [CLIENT]: Applied keybind -" @ KeyConfig.DefaultKeybindings[i].KeyName @ "=" @ KeyConfig.DefaultKeybindings[i].Command);
        }
        else
        {
            `log("ZTPlayerController [CLIENT]: Skipped keybind -" @ KeyConfig.DefaultKeybindings[i].KeyName @ "(already bound to critical command)");
        }
    }
    
    `log("ZTPlayerController [CLIENT]: Applied" @ SuccessCount @ "of" @ KeyConfig.DefaultKeybindings.Length @ "default keybindings");
}

simulated function bool ShouldOverrideKey(string KeyName)
{
    local PlayerInput PlayerInputRef;
    local int i, j;
    local string ExistingCommand;
    local array<string> ProtectedCommands;
    
    // Critical gameplay commands that should never be overridden
    ProtectedCommands.AddItem("GBA_Fire");
    ProtectedCommands.AddItem("GBA_AltFire");
    ProtectedCommands.AddItem("GBA_Reload");
    ProtectedCommands.AddItem("GBA_Use");
    ProtectedCommands.AddItem("GBA_Jump");
    ProtectedCommands.AddItem("GBA_Crouch");
    ProtectedCommands.AddItem("GBA_MoveForward");
    ProtectedCommands.AddItem("GBA_MoveBackward");
    ProtectedCommands.AddItem("GBA_StrafeLeft");
    ProtectedCommands.AddItem("GBA_StrafeRight");
    ProtectedCommands.AddItem("GBA_Sprint");
    ProtectedCommands.AddItem("GBA_IronSights");
    ProtectedCommands.AddItem("GBA_Melee");
    ProtectedCommands.AddItem("GBA_WeaponSelect");
    ProtectedCommands.AddItem("GBA_NextWeapon");
    ProtectedCommands.AddItem("GBA_PrevWeapon");
    ProtectedCommands.AddItem("GBA_ToggleFlashlight");
    
    PlayerInputRef = PlayerInput;
    if (PlayerInputRef == None)
        return false;
    
    // Check if key is bound to something
    for (i = 0; i < PlayerInputRef.Bindings.Length; i++)
    {
        if (PlayerInputRef.Bindings[i].Name == name(KeyName))
        {
            ExistingCommand = PlayerInputRef.Bindings[i].Command;
            
            // Check if it's a protected command
            for (j = 0; j < ProtectedCommands.Length; j++)
            {
                if (InStr(ExistingCommand, ProtectedCommands[j]) != INDEX_NONE)
                    return true;
            }
        }
    }
    
    return false;
}

// ===================================================================
// KEYBINDING UTILITY COMMANDS
// ===================================================================

// Show current keybindings
exec function DKShowKeybinds()
{
    local ZT_Config_Keybindings KeyConfig;
    local int i;
    
    KeyConfig = new class'ZT_Config_Keybindings';
    class'ZT_Config_Keybindings'.static.InitializeDefaults(KeyConfig);
    
    ClientMessage("===============================================");
    ClientMessage("    Zedternal RB Perkpackage Keybindings");
    ClientMessage("===============================================");
    
    for (i = 0; i < KeyConfig.DefaultKeybindings.Length; i++)
    {
        ClientMessage("  " $ KeyConfig.DefaultKeybindings[i].KeyName @ "-" @ KeyConfig.DefaultKeybindings[i].Description);
    }
    
    ClientMessage("===============================================");
}

// Reset to defaults
exec function DKResetKeybinds()
{
    local ZT_Config_Keybindings KeyConfig;
    
    KeyConfig = new class'ZT_Config_Keybindings';
    class'ZT_Config_Keybindings'.static.InitializeDefaults(KeyConfig);
    
    KeyConfig.bHasAppliedDefaults = false;
    KeyConfig.SaveConfig();
    
    bHasCheckedKeybindings = false;
    CheckAndApplyDefaultKeybindings();
    
    ClientMessage("Keybindings reset to defaults!");
}

// Clear all custom keybindings
exec function DKClearKeybinds()
{
    local ZT_Config_Keybindings KeyConfig;
    local int i;
    
    KeyConfig = new class'ZT_Config_Keybindings';
    class'ZT_Config_Keybindings'.static.InitializeDefaults(KeyConfig);
    
    for (i = 0; i < KeyConfig.DefaultKeybindings.Length; i++)
    {
        ConsoleCommand("SetBind" @ KeyConfig.DefaultKeybindings[i].KeyName);
    }
    
    KeyConfig.bHasAppliedDefaults = false;
    KeyConfig.SaveConfig();
    
    ClientMessage("Custom keybindings cleared!");
}

// ===================================================================
// PERK LIMIT ENFORCEMENT
// Blocks buying NEW perks (level 0->1) once the player has reached
// the configured maximum number of different perks.
// Upgrading existing perks (level 1->2, etc.) is always allowed.
//
// PAGED PERK SUPPORT: All reads/writes go through DKPRI helpers so the
// 256..1023 range works correctly. For ItemDefinition >= 256 the parent
// Super.BuyPerkUpgrade would write OOB into bPerkUpgrade[256+], so we
// run a manual buy path that mirrors WMPlayerController.BuyPerkUpgrade
// but writes via IncrementPerkLevel.
// ===================================================================

reliable server function BuyPerkUpgrade(int ItemDefinition, int Cost)
{
	local ZTPlayerReplicationInfo DKPRI;
	local WMGameReplicationInfo WMGRI;
	local int MaxPerks, OwnedPerkCount, i;
	local int CurrentLevel, R1Level, R2Level, MaxR1, MaxR2;
	local int R1Count, R2Count;
	local int PerkCap;
	local int MaxLevel, MaxedPerkCount, Lvl, EffectiveCap;

	if (Pawn == None) return;
	DKPRI = ZTPlayerReplicationInfo(Pawn.PlayerReplicationInfo);
	if (DKPRI == None) return;

	CurrentLevel = DKPRI.GetPerkLevel(ItemDefinition);
	PerkCap = class'ZTPlayerReplicationInfo'.const.DK_MAX_PERKS;

	// --- Perk diversity limit ---
	MaxPerks = class'ZTConfig_PerkLimit'.default.Player_MaxDifferentPerks;
	if (MaxPerks > 0 && CurrentLevel == 0)
	{
		MaxLevel = class'ZedternalReborn.Config_PerkUpgradeOptions'.default.PerkUpgrade_Price.Length;
		OwnedPerkCount = 0;
		MaxedPerkCount = 0;
		for (i = 0; i < PerkCap; ++i)
		{
			Lvl = DKPRI.GetPerkLevel(i);
			if (Lvl > 0)
				++OwnedPerkCount;
			if (MaxLevel > 0 && Lvl >= MaxLevel)
				++MaxedPerkCount;
		}

		// Progressive unlock (opt-in): cap grows by 1 per owned perk taken to
		// max level, so a new slot opens only once the current perks are fully
		// leveled. Disabled => flat MaxDifferentPerks cap. Authoritative check;
		// ZTUI_UPGMenu.ClientPerkBuyAllowed mirrors this for the client pre-check.
		if (class'ZTConfig_PerkLimit'.default.Player_ProgressivePerkUnlock)
			EffectiveCap = Max(MaxPerks, MaxedPerkCount + 1);
		else
			EffectiveCap = MaxPerks;

		if (OwnedPerkCount >= EffectiveCap)
		{
			ClientMessage("Perk limit reached! You can own at most" @ EffectiveCap @ "different perks right now.");
			return;
		}
	}

	// --- Capstone max-active limits ---
	R1Level = class'ZTConfig_Capstone'.default.Capstone_Rank1Level;
	R2Level = class'ZTConfig_Capstone'.default.Capstone_Rank2Level;
	MaxR1 = class'ZTConfig_Capstone'.default.Capstone_MaxActiveRank1;
	MaxR2 = class'ZTConfig_Capstone'.default.Capstone_MaxActiveRank2;

	// Check Rank 1 capstone limit: player is about to reach R1Level
	if (MaxR1 > 0 && CurrentLevel == (R1Level - 1))
	{
		R1Count = 0;
		for (i = 0; i < PerkCap; ++i)
		{
			if (DKPRI.GetPerkLevel(i) >= R1Level)
				++R1Count;
		}
		if (R1Count >= MaxR1)
		{
			ClientMessage("Capstone limit reached! You can have at most" @ MaxR1 @ "Rank 1 capstones (Level" @ R1Level $ ").");
			return;
		}
	}

	// Check Rank 2 capstone limit: player is about to reach R2Level
	if (MaxR2 > 0 && CurrentLevel == (R2Level - 1))
	{
		R2Count = 0;
		for (i = 0; i < PerkCap; ++i)
		{
			if (DKPRI.GetPerkLevel(i) >= R2Level)
				++R2Count;
		}
		if (R2Count >= MaxR2)
		{
			ClientMessage("Capstone limit reached! You can have at most" @ MaxR2 @ "Rank 2 capstones (Level" @ R2Level $ ").");
			return;
		}
	}

	// All checks passed -- dispatch to parent or paged manual buy
	if (ItemDefinition >= 0 && ItemDefinition < 256)
	{
		// Parent path: writes to bPerkUpgrade[0..255] safely
		Super.BuyPerkUpgrade(ItemDefinition, Cost);
	}
	else if (ItemDefinition >= 256 && ItemDefinition < PerkCap)
	{
		// Paged manual buy: mirror WMPlayerController.BuyPerkUpgrade
		// but write via IncrementPerkLevel to hit bPerkUpgrade_2/3/4.
		WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
		if (WMGRI == None) return;
		if (DKPRI.Score < Cost) return;
		if (CurrentLevel >= WMGRI.PerkUpgMaxLevel) return;

		DKPRI.IncrementPerkLevel(ItemDefinition);
		if (DKPRI.Purchase_PerkUpgrade.Find(ItemDefinition) == INDEX_NONE)
			DKPRI.Purchase_PerkUpgrade.AddItem(ItemDefinition);

		if (WorldInfo.NetMode == NM_DedicatedServer)
		{
			DKPRI.AddDosh(-Cost);
			DKPRI.SyncTrigger = !DKPRI.SyncTrigger;
		}

		UpdateWeaponMagAndCap();
		DKPRI.UpdateCurrentIconToDisplay(ItemDefinition, Cost, 1);
	}
}

// ===================================================================
// ABILITY ACTIVATION (CONSOLE COMMANDS)
// ===================================================================

exec function ActivateAbility1()
{
    ServerActivateAbilitySlot(0);
}

exec function ActivateAbility2()
{
    ServerActivateAbilitySlot(1);
}

exec function ActivateAbility3()
{
    ServerActivateAbilitySlot(2);
}

exec function ActivateAbility4()
{
    ServerActivateAbilitySlot(3);
}

// ===================================================================
// JEKYLL & HYDE - dedicated serum key (default H), bypasses the 4 ability
// slots so it can never be displaced or blocked by a full slot bar.
// ===================================================================
exec function ActivateHyde()
{
    ServerActivateHyde();
}

reliable server function ServerActivateHyde()
{
    local ZTUpgrade_Perk_JekyllHyde_Helper H;

    if (Pawn == None)
        return;

    H = class'ZTUpgrade_Perk_JekyllHyde'.static.GetHelper(Pawn);
    if (H == None)
    {
        class'ZTMessageManager'.static.SendMinor(self, "Hyde Serum: you do not have the Jekyll & Hyde perk.");
        return;
    }

    H.TryActivate();
}

// ===================================================================
// DOMAIN PERK - hold-to-wheel active. Press casts the Room (or opens the
// ability wheel if the Room is already up); release fires the highlighted
// wheel segment. Recommended bind: "DomainPress | OnRelease DomainRelease".
// ===================================================================
exec function DomainPress()
{
    ServerDomainPress();
}

reliable server function ServerDomainPress()
{
    local ZTUpgrade_Perk_Domain_Helper H;

    if (Pawn == None)
        return;

    H = class'ZTUpgrade_Perk_Domain'.static.FindHelper(Pawn);
    if (H == None)
    {
        class'ZTMessageManager'.static.SendMinor(self, "Domain: you do not have the Domain perk.");
        return;
    }

    if (H.CanCastRoom())
        H.CastRoom();
    else if (H.bRoomActive)
        ClientOpenDomainWheel(H.BuildCooldownSnapshot());
}

reliable client function ClientOpenDomainWheel(string CooldownData)
{
    if (DomainWheelMovie != None)
        return;

    DomainWheelMovie = new class'ZTDomainWheelMovie';
    DomainWheelMovie.DKPC = self;
    DomainWheelMovie.PendingCooldownData = CooldownData;
    DomainWheelMovie.SetTimingMode(TM_Real);
    DomainWheelMovie.Init(LocalPlayer(Player));
    if (!DomainWheelMovie.OpenWheel(self))
        DomainWheelMovie = None;
}

// The wheel now uses the click-to-fire CommandWheel SWF: it commits on
// left-click (Callback_SlotSelected -> ServerFireDomainAction) and closes
// itself. Key release no longer fires anything. Kept as a no-op so the
// "DomainPress | OnRelease DomainRelease" bind still resolves cleanly.
exec function DomainRelease()
{
}

reliable server function ServerFireDomainAction(int ActionIndex)
{
    local ZTUpgrade_Perk_Domain_Helper H;

    if (Pawn == None)
        return;

    H = class'ZTUpgrade_Perk_Domain'.static.FindHelper(Pawn);
    if (H != None)
        H.FireAction(ActionIndex);
}

// Debug: fire a Domain action directly, no wheel, bypassing the unlock gate
// (pre-SWF gameplay testing).
exec function DomainDbg(int ActionIndex)
{
    ServerFireDomainActionDebug(ActionIndex);
}

reliable server function ServerFireDomainActionDebug(int ActionIndex)
{
    local ZTUpgrade_Perk_Domain_Helper H;

    if (Pawn == None)
        return;

    H = class'ZTUpgrade_Perk_Domain'.static.FindHelper(Pawn);
    if (H != None)
        H.FireAction(ActionIndex, true);
}

// ===================================================================
// POSSESSOR PERK - form-wheel active on the dedicated O key.
// Press while human -> open the form wheel (CommandWheel SWF); click a
// wedge -> possess that form via the puppet machinery. Press while
// possessed -> revert early. Timer expiry / lethal damage / wave end all
// revert automatically. Recommended bind: "PossessorPress".
// ===================================================================
exec function PossessorPress()
{
    ServerPossessorPress();
}

reliable server function ServerPossessorPress()
{
    local ZTUpgrade_Perk_Possessor_Helper H;
    local int RemainingSecs;

    // Already driving a puppet: this press is a revert request. Only handle
    // perk-driven possessions here - debug spike puppets keep using PuppetDrop.
    if (PuppetZed != None && PuppetSavedHuman != None)
    {
        H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(PuppetSavedHuman);
        if (H != None && H.bPossessing)
            ServerPuppetDrop();
        return;
    }

    if (Pawn == None)
        return;

    H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(Pawn);
    if (H == None)
    {
        class'ZTMessageManager'.static.SendMinor(self, "Possession: you do not have the Possessor perk.");
        return;
    }

    if (H.bOnCooldown)
    {
        RemainingSecs = int(H.GetCooldown() - (WorldInfo.TimeSeconds - H.CooldownStart)) + 1;
        class'ZTMessageManager'.static.SendMinor(self, "Possession recharging: " $ RemainingSecs $ "s");
        return;
    }

    if (!H.CanPossess())
        return;

    ClientOpenPossessorWheel(H.BuildWheelSnapshot());
}

reliable client function ClientOpenPossessorWheel(string SnapshotData)
{
    if (PossessorWheelMovie != None)
        return;

    PossessorWheelMovie = new class'ZTPossessorWheelMovie';
    PossessorWheelMovie.DKPC = self;
    PossessorWheelMovie.PendingSnapshotData = SnapshotData;
    PossessorWheelMovie.SetTimingMode(TM_Real);
    PossessorWheelMovie.Init(LocalPlayer(Player));
    if (!PossessorWheelMovie.OpenWheel(self))
        PossessorWheelMovie = None;
}

reliable server function ServerFirePossessorForm(int FormIndex)
{
    local ZTUpgrade_Perk_Possessor_Helper H;

    if (Pawn == None)
        return;

    H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(Pawn);
    if (H != None)
        H.FirePossess(FormIndex);
}

// Called by ServerPuppetDrop (the single revert funnel) so the Possessor
// helper can start its cooldown + flip the HUD card. Must run BEFORE the
// puppet refs are nulled. No-op for debug spike puppets (no helper / not
// flagged as possessing).
function NotifyPossessorHelperDropped()
{
    local ZTUpgrade_Perk_Possessor_Helper H;

    if (PuppetSavedHuman == None)
        return;

    H = class'ZTUpgrade_Perk_Possessor'.static.FindHelper(PuppetSavedHuman);
    if (H != None)
        H.NotifyPossessionEnded();
}

// Server function to activate ability in a slot
reliable server function ServerActivateAbilitySlot(int SlotIndex)
{
    local AbilitySlotData Slot;
    local ZTUpgrade_Skill_Swiftness_Helper SwiftnessHelper;
    local ZTUpgrade_Skill_TacticalFocus_Helper TacticalFocusHelper;
    local ZTUpgrade_Skill_ExplosiveFury_Helper ExplosiveFuryHelper;
    local ZTUpgrade_Skill_FieldSurgery_Helper FieldSurgeryHelper;
    local ZTUpgrade_Skill_PyromaniacRush_Helper PyromaniacRushHelper;
    local ZTUpgrade_Skill_QuickDraw_Helper QuickDrawHelper;
    local ZTUpgrade_Skill_ScavengersLuck_Helper ScavengersLuckHelper;
    local ZTUpgrade_Skill_TacticalShield_Helper TacticalShieldHelper;
    local ZTUpgrade_Skill_BreachingCharge_Helper BreachingChargeHelper;
    local ZTUpgrade_Skill_DeadEye_Helper DeadEyeHelper;
    local ZTUpgrade_Skill_Chronoshift_Helper ChronoshiftHelper;
    local ZTUpgrade_Skill_Inferno_Helper InfernoHelper;
    local ZTUpgrade_Skill_Bullseye_Helper BullseyeHelper;
    local ZTUpgrade_Skill_Wallhack_Helper WallhackHelper;
    
    if (SlotIndex < 0 || SlotIndex >= AbilitySlots.Length)
    {
        class'ZTMessageManager'.static.SendMinorLoc(self, 'AbilitySlotEmpty', string(SlotIndex + 1));
        return;
    }
    
    Slot = AbilitySlots[SlotIndex];
    if (Slot.Helper == None)
    {
        class'ZTMessageManager'.static.SendMinorLoc(self, 'AbilitySlotEmpty', string(SlotIndex + 1));
        return;
    }
    
    // Route to the appropriate helper based on class
    SwiftnessHelper = ZTUpgrade_Skill_Swiftness_Helper(Slot.Helper);
    if (SwiftnessHelper != None)
    {
        SwiftnessHelper.TryActivate();
        return;
    }
    
    TacticalFocusHelper = ZTUpgrade_Skill_TacticalFocus_Helper(Slot.Helper);
    if (TacticalFocusHelper != None)
    {
        TacticalFocusHelper.TryActivate();
        return;
    }
    
    ExplosiveFuryHelper = ZTUpgrade_Skill_ExplosiveFury_Helper(Slot.Helper);
    if (ExplosiveFuryHelper != None)
    {
        ExplosiveFuryHelper.TryActivate();
        return;
    }
    
    FieldSurgeryHelper = ZTUpgrade_Skill_FieldSurgery_Helper(Slot.Helper);
    if (FieldSurgeryHelper != None)
    {
        FieldSurgeryHelper.TryActivate();
        return;
    }
    
    PyromaniacRushHelper = ZTUpgrade_Skill_PyromaniacRush_Helper(Slot.Helper);
    if (PyromaniacRushHelper != None)
    {
        PyromaniacRushHelper.TryActivate();
        return;
    }
    
    QuickDrawHelper = ZTUpgrade_Skill_QuickDraw_Helper(Slot.Helper);
    if (QuickDrawHelper != None)
    {
        QuickDrawHelper.TryActivate();
        return;
    }
    
    ScavengersLuckHelper = ZTUpgrade_Skill_ScavengersLuck_Helper(Slot.Helper);
    if (ScavengersLuckHelper != None)
    {
        ScavengersLuckHelper.TryActivate();
        return;
    }
    
    TacticalShieldHelper = ZTUpgrade_Skill_TacticalShield_Helper(Slot.Helper);
    if (TacticalShieldHelper != None)
    {
        TacticalShieldHelper.TryActivate();
        return;
    }
    
    BreachingChargeHelper = ZTUpgrade_Skill_BreachingCharge_Helper(Slot.Helper);
    if (BreachingChargeHelper != None)
    {
        BreachingChargeHelper.TryActivate();
        return;
    }
    
    DeadEyeHelper = ZTUpgrade_Skill_DeadEye_Helper(Slot.Helper);
    if (DeadEyeHelper != None)
    {
        DeadEyeHelper.TryActivate();
        return;
    }
    
    ChronoshiftHelper = ZTUpgrade_Skill_Chronoshift_Helper(Slot.Helper);
    if (ChronoshiftHelper != None)
    {
        ChronoshiftHelper.TryActivate();
        return;
    }
    
    InfernoHelper = ZTUpgrade_Skill_Inferno_Helper(Slot.Helper);
    if (InfernoHelper != None)
    {
        InfernoHelper.TryActivate();
        return;
    }
    
    BullseyeHelper = ZTUpgrade_Skill_Bullseye_Helper(Slot.Helper);
    if (BullseyeHelper != None)
    {
        BullseyeHelper.TryActivate();
        return;
    }
    
    WallhackHelper = ZTUpgrade_Skill_Wallhack_Helper(Slot.Helper);
    if (WallhackHelper != None)
    {
        WallhackHelper.TryActivate();
        return;
    }
    
    // If we get here, the helper class is not recognized
    class'ZTMessageManager'.static.SendMinorLoc(self, 'UnknownAbilityType', string(SlotIndex + 1));
}

// ===================================================================
// ABILITY REGISTRATION SYSTEM
// ===================================================================

function bool RegisterAbility(string AbilityName, Info Helper, class<Info> HelperClass, optional Texture2D AbilityIcon)
{
    local AbilitySlotData NewSlot;
    local int EmptySlot;
    local Info OldHelper;
    
    if (Helper == None || HelperClass == None)
        return false;
    
    // Check if this helper already exists
    EmptySlot = FindSlotByHelper(Helper);
    if (EmptySlot != INDEX_NONE)
    {
        `log("ZTPlayerController: Ability already registered in slot" @ EmptySlot);
        return true;
    }
    
    // DK FIX: Class-based slot replacement. On death the old pawn's helper
    // is never destroyed (the slot keeps a stale instance whose OwnerPawn is
    // the corpse) and on respawn InitiateWeapon spawns a fresh helper that
    // would register into a NEW slot -> duplicate ability entries plus a
    // haunted slot that reports "cannot activate while dead" forever.
    // Instead: if a slot already holds a helper of the same class, take over
    // THAT slot and destroy the stale instance. Overwrite first, destroy
    // second, so the old helper's Destroyed->Cleanup->UnregisterAbility
    // no-ops (it is no longer found in any slot).
    EmptySlot = FindSlotByHelperClass(HelperClass);
    if (EmptySlot != INDEX_NONE)
    {
        OldHelper = AbilitySlots[EmptySlot].Helper;

        AbilitySlots[EmptySlot].Helper = Helper;
        AbilitySlots[EmptySlot].AbilityName = AbilityName;
        AbilitySlots[EmptySlot].HelperClass = HelperClass;
        AbilitySlots[EmptySlot].AbilityIcon = AbilityIcon;

        if (OldHelper != None && OldHelper != Helper)
            OldHelper.Destroy();

        ClientRegisterAbility(EmptySlot, AbilityName, AbilityIcon);

        `log("ZTPlayerController: Replaced stale" @ HelperClass @ "ability in slot" @ EmptySlot);
        return true;
    }
    
    // Find first empty slot
    EmptySlot = FindEmptySlot();
    
    if (EmptySlot == INDEX_NONE)
    {
        class'ZTMessageManager'.static.SendImportantLoc(self, 'AllAbilitySlotsFull');
        return false;
    }
    
    // Register in the slot
    NewSlot.Helper = Helper;
    NewSlot.AbilityName = AbilityName;
    NewSlot.HelperClass = HelperClass;
    NewSlot.AbilityIcon = AbilityIcon;
    
    if (EmptySlot >= AbilitySlots.Length)
        AbilitySlots.AddItem(NewSlot);
    else
        AbilitySlots[EmptySlot] = NewSlot;
    
    // Update HUD via client RPC
    ClientRegisterAbility(EmptySlot, AbilityName, AbilityIcon);
    
    class'ZTMessageManager'.static.SendImportantLoc(self, 'AbilityAdded', AbilityName, string(EmptySlot + 1));
    
    `log("ZTPlayerController: Registered ability" @ AbilityName @ "in slot" @ EmptySlot);
    return true;
}

reliable client function ClientRegisterAbility(int SlotIndex, string AbilityName, Texture2D AbilityIcon)
{
    local ZTGFxScoreBoardWrapper HUD;
    local string HUDTypeName;
    
    HUD = ZTGFxScoreBoardWrapper(myHUD);
    if (HUD != None)
    {
        HUD.UpdateAbilitySlot(SlotIndex, AbilityName, true, AbilityIcon);
        `log("ZTPlayerController (CLIENT): Registered ability" @ AbilityName @ "in HUD slot" @ SlotIndex);
    }
    else
    {
        if (myHUD != None)
            HUDTypeName = string(myHUD.Class.Name);
        else
            HUDTypeName = "NONE";
        
        `log("ZTPlayerController (CLIENT): ERROR - HUD is not ZTGFxScoreBoardWrapper! Actual type:" @ HUDTypeName);
    }
}

function bool UnregisterAbility(Info Helper)
{
    local int SlotIndex;
    
    if (Helper == None)
        return false;
    
    SlotIndex = FindSlotByHelper(Helper);
    if (SlotIndex == INDEX_NONE)
        return false;
    
    // Clear the slot
    AbilitySlots[SlotIndex].Helper = None;
    AbilitySlots[SlotIndex].AbilityName = "";
    AbilitySlots[SlotIndex].HelperClass = None;
    AbilitySlots[SlotIndex].AbilityIcon = None;
    
    // Update HUD via client RPC
    ClientUnregisterAbility(SlotIndex);
    
    `log("ZTPlayerController: Unregistered ability from slot" @ SlotIndex);
    return true;
}

reliable client function ClientUnregisterAbility(int SlotIndex)
{
    local ZTGFxScoreBoardWrapper HUD;
    
    HUD = ZTGFxScoreBoardWrapper(myHUD);
    if (HUD != None)
    {
        HUD.UpdateAbilitySlot(SlotIndex, "", false, None);
        `log("ZTPlayerController (CLIENT): Unregistered ability from HUD slot" @ SlotIndex);
    }
}

reliable client function ClientUpdateAbilityHUD(int SlotIndex, bool bIsActive, bool bIsOnCooldown, float RemainingTime, float MaxTime)
{
    local ZTGFxScoreBoardWrapper HUD;
    
    HUD = ZTGFxScoreBoardWrapper(myHUD);
    if (HUD != None)
    {
        HUD.UpdateAbilityState(SlotIndex, bIsActive, bIsOnCooldown, RemainingTime, MaxTime);
    }
}

// ===================================================================
// WENDIGO HUD TRACKERS - client RPCs
// The Wendigo helper is a server-side, non-replicated Info; its old
// 'reliable client' UpdateStalkerDisplay was silently dropped on
// dedicated servers (RemoteRole=ROLE_None actors cannot send client
// RPCs) and its notifications used GetALocalPlayerController(), which
// is always None on dedicated. All Wendigo HUD traffic now routes
// through the owning controller.
// AmbushState/ApexState: 0=hide, 1=ready/building, 2=triggered/active
// ===================================================================

reliable client function ClientUpdateWendigoTrackers(int StalkSeconds, bool bStalkActive, byte AmbushState, int ApexSeconds, byte ApexState)
{
    local ZTHudWrapper WendigoHUD;

    WendigoHUD = class'ZTHudWrapper'.static.GetReaperHUD(self);
    if (WendigoHUD == None)
        return;

    // Stalking bonus tracker (5+ seconds not firing)
    if (bStalkActive)
        WendigoHUD.UpdateWendigoStalkingBonus(Min(StalkSeconds, 15), 15, true, 8.0f);
    else
        WendigoHUD.UpdateWendigoStalkingBonus(0, 15, false, 0.0f);

    // Perfect ambush tracker
    if (AmbushState == 2)
        WendigoHUD.UpdateWendigoPerfectAmbush(false, true, 5.0f);
    else if (AmbushState == 1)
        WendigoHUD.UpdateWendigoPerfectAmbush(true, false, 8.0f);
    else
        WendigoHUD.UpdateWendigoPerfectAmbush(false, false, 0.0f);

    // Apex stalker tracker
    if (ApexState == 2)
        WendigoHUD.UpdateWendigoApexStalker(30, 30, true, 10.0f);
    else if (ApexState == 1)
        WendigoHUD.UpdateWendigoApexStalker(Min(ApexSeconds, 30), 30, false, 8.0f);
    else
        WendigoHUD.UpdateWendigoApexStalker(0, 30, false, 0.0f);
}

reliable client function ClientWendigoChainNotification(string NotifTitle, string NotifSubtitle, float NotifDuration)
{
    local ZTHudWrapper WendigoHUD;

    WendigoHUD = class'ZTHudWrapper'.static.GetReaperHUD(self);
    if (WendigoHUD != None)
        WendigoHUD.TriggerChainNotification(NotifTitle, NotifSubtitle, NotifDuration);
}

// ===================================================================
// CUSTOM SOUND REPLICATION
// ===================================================================

reliable client function ClientPlayChronoshiftSound(SoundCue ActivationSound)
{
    if (ActivationSound != None && Pawn != None)
    {
        Pawn.PlaySound(ActivationSound, true);
        `log("ZTPlayerController [CLIENT]: Played Chronoshift activation sound");
    }
}

reliable client function ClientPlayAchievementSound(SoundCue AchievementSound)
{
    if (AchievementSound != None && Pawn != None)
    {
        Pawn.PlaySound(AchievementSound, true);
        `log("ZTPlayerController [CLIENT]: Played achievement unlock sound");
    }
}

reliable client function ClientPlayPerkUnlockSound(SoundCue PerkUnlockSound)
{
    if (PerkUnlockSound != None && Pawn != None)
    {
        Pawn.PlaySound(PerkUnlockSound, true);
        `log("ZTPlayerController [CLIENT]: Played perk unlock sound");
    }
}

reliable client function ClientPlayInfernoSound(SoundCue InfernoSound)
{
    if (InfernoSound != None && Pawn != None)
    {
        Pawn.PlaySoundBase(InfernoSound, true, true);
        `log("ZTPlayerController (CLIENT): Played Inferno sound");
    }
}

reliable client function ClientPlayPhoenixProtocolSound(SoundCue PhoenixSound)
{
    if (PhoenixSound != None && Pawn != None)
    {
        Pawn.PlaySoundBase(PhoenixSound, true, true);
        `log("ZTPlayerController (CLIENT): Played Phoenix Protocol sound");
    }
}

reliable client function ClientPlayWraithFormSound(SoundCue WraithSound)
{
    if (WraithSound != None && Pawn != None)
    {
        Pawn.PlaySoundBase(WraithSound, true, true);
        `log("ZTPlayerController (CLIENT): Played Wraith Form sound");
    }
}

reliable client function ClientPlayWatcherSound(SoundCue WatcherSound)
{
    if (WatcherSound != None && Pawn != None)
    {
        Pawn.PlaySoundBase(WatcherSound, true, true);
        `log("ZTPlayerController (CLIENT): Played Watcher sound");
    }
}

// Watcher visuals are generated by a server-only helper. They must travel
// through the replicated owning controller to reach dedicated-server clients.
unreliable client function ClientUpdateWatcherHUD(
    bool bActive,
    int Stage,
    float Vignette,
    bool bStaticFlash,
    bool bSubliminal,
    string SubText,
    float SubX,
    float SubY,
    bool bDim,
    bool bInvert,
    bool bScan,
    float ScanY)
{
    local ZTHudWrapper WatcherHUD;

    WatcherHUD = class'ZTHudWrapper'.static.GetReaperHUD(self);
    if (WatcherHUD == None)
        return;

    WatcherHUD.UpdateWatcherEffects(
        bActive, Stage, Vignette, bStaticFlash, bSubliminal, SubText,
        SubX, SubY, bDim, bInvert, bScan, ScanY);
}

unreliable client function ClientSetWatcherEyeCount(int Count)
{
    local ZTHudWrapper WatcherHUD;

    WatcherHUD = class'ZTHudWrapper'.static.GetReaperHUD(self);
    if (WatcherHUD != None)
        WatcherHUD.SetWatcherEyeCount(Count);
}

unreliable client function ClientUpdateWatcherEye(
    int EyeIndex,
    float PosX,
    float PosY,
    float Size,
    float Alpha,
    float PupilOffX,
    float PupilOffY,
    bool bBlinkingState,
    float BlinkTime)
{
    local ZTHudWrapper WatcherHUD;

    WatcherHUD = class'ZTHudWrapper'.static.GetReaperHUD(self);
    if (WatcherHUD == None)
        return;

    WatcherHUD.UpdateWatcherEye(
        EyeIndex, PosX, PosY, Size, Alpha, PupilOffX, PupilOffY,
        bBlinkingState, BlinkTime);
}

// ===================================================================
// AMMO REFUND (LuckyShot / SymbioticRounds)
// ===================================================================
// Headshot ammo-refund skills run inside the server-side ModifyDamageGiven
// hook, where a bare "KFW.AmmoCount[0] += 1" only touches the SERVER weapon.
// The owning client predicts its own magazine, so that write never reliably
// reaches it -- the refund silently does nothing on dedicated/remote clients.
// This mirrors the proven AmmoSiphon pattern: write authoritatively on the
// server, then replicate the same delta to the owning client. For a locally
// controlled player (standalone / listen host) the server weapon IS the
// client weapon, so the RPC is skipped to avoid double-applying.
function RefundWeaponAmmo(KFWeapon KFW, int MagAmount, int SpareAmount)
{
    if (KFW == None)
        return;

    if (MagAmount > 0)
        KFW.AmmoCount[0] = Min(KFW.AmmoCount[0] + MagAmount, KFW.MagazineCapacity[0]);
    if (SpareAmount > 0)
        KFW.SpareAmmoCount[0] = Min(KFW.SpareAmmoCount[0] + SpareAmount, KFW.GetMaxAmmoAmount(0));

    if (!IsLocalPlayerController())
        ClientRefundWeaponAmmo(MagAmount, SpareAmount);
}

reliable client function ClientRefundWeaponAmmo(int MagAmount, int SpareAmount)
{
    local KFWeapon KFW;

    if (Pawn == None)
        return;

    KFW = KFWeapon(Pawn.Weapon);
    if (KFW == None)
        return;

    if (MagAmount > 0)
        KFW.AmmoCount[0] = Min(KFW.AmmoCount[0] + MagAmount, KFW.MagazineCapacity[0]);
    if (SpareAmount > 0)
        KFW.SpareAmmoCount[0] = Min(KFW.SpareAmmoCount[0] + SpareAmount, KFW.GetMaxAmmoAmount(0));
}

reliable client function ClientPlayBuffSound(SoundCue BuffSound)
{
    if (BuffSound != None && Pawn != None)
    {
        Pawn.PlaySoundBase(BuffSound, true, true);
    }
}

// ===================================================================
// DOMAIN HUD CARD
// ===================================================================
// Routed through the controller (not the helper) so it works on dedicated
// servers, same as the Wendigo trackers. State: 0=Ready, 1=Active, 2=Cooldown.

reliable client function ClientUpdateDomainHUD(byte State, float Duration)
{
    local ZTHudWrapper DomainHUD;

    DomainHUD = class'ZTHudWrapper'.static.GetReaperHUD(self);
    if (DomainHUD != None)
        DomainHUD.UpdateDomainDisplay(State, Duration);
}

reliable client function ClientClearDomainHUD()
{
    local ZTHudWrapper DomainHUD;

    DomainHUD = class'ZTHudWrapper'.static.GetReaperHUD(self);
    if (DomainHUD != None)
        DomainHUD.ClearDomainDisplay();
}

reliable client function ClientPlayDetonatorSound(SoundCue DetonatorSound)
{
    if (DetonatorSound != None && Pawn != None)
    {
        Pawn.PlaySoundBase(DetonatorSound, true, true);
        `log("ZTPlayerController (CLIENT): Played Detonator sound");
    }
}

// ===================================================================
// EVENT WAVE MUSIC
// Uses AudioComponent for persistent playback with fade-out support.
// SoundCue should use SoundNodeLooper in the UPK for looping.
// ===================================================================

reliable client function ClientPlayEventMusic(SoundCue MusicCue)
{
    // Stop any existing event music first
    if (EventMusicComponent != None)
    {
        EventMusicComponent.Stop();
        EventMusicComponent = None;
    }

    if (MusicCue != None && Pawn != None)
    {
        EventMusicComponent = Pawn.CreateAudioComponent(MusicCue, False, True);
        if (EventMusicComponent != None)
        {
            EventMusicComponent.bAutoDestroy = False;
            EventMusicComponent.bShouldRemainActiveIfDropped = True;
            EventMusicComponent.bIsUISound = True;
            EventMusicComponent.VolumeMultiplier = class'ZTConfig_HudPreferences'.static.GetEventMusicVolume();
            EventMusicComponent.Play();
        }
    }

    // Mute KF2 native music and keep it muted
    SuppressNativeMusic();
    SetTimer(0.25, True, nameof(SuppressNativeMusic));
}

reliable client function ClientStopEventMusic(float FadeOutDuration)
{
    // Stop suppressing KF2 native music ? it will naturally resume next wave
    ClearTimer(nameof(SuppressNativeMusic));

    if (EventMusicComponent != None)
    {
        if (FadeOutDuration > 0)
        {
            EventMusicComponent.FadeOut(FadeOutDuration, 0.0);
            SetTimer(FadeOutDuration + 0.5, False, nameof(CleanupEventMusic));
        }
        else
        {
            EventMusicComponent.Stop();
            EventMusicComponent = None;
        }
    }
}

// X-Men power assignment RPC
reliable client function ClientReceiveXMenPower(string PowerName, string PowerDesc)
{
    XMenPowerName = PowerName;
    XMenPowerDesc = PowerDesc;
    `log("[DK_XMEN] Received power:" @ PowerName @ "-" @ PowerDesc);
}

/** Repeatedly stops KF2 Wwise music while event music is playing.
 *  KF2's GRI OneSecondLoop re-triggers PlayNewMusicTrack when MusicComp
 *  stops playing, so we must keep killing it on a timer. */
simulated function SuppressNativeMusic()
{
    local KFGameReplicationInfo KFGRI;

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
    if (KFGRI != None && KFGRI.MusicComp != None)
    {
        KFGRI.MusicComp.StopEvents();
    }
}

simulated function CleanupEventMusic()
{
    if (EventMusicComponent != None)
    {
        EventMusicComponent.Stop();
        EventMusicComponent = None;
    }
}

// ===================================================================
// UTILITY FUNCTIONS
// ===================================================================

function int FindEmptySlot()
{
    local int i;
    
    for (i = 0; i < AbilitySlots.Length; i++)
    {
        if (AbilitySlots[i].Helper == None)
            return i;
    }
    
    if (AbilitySlots.Length < 4)
        return AbilitySlots.Length;
    
    return INDEX_NONE;
}

function int FindSlotByHelper(Info Helper)
{
    local int i;
    
    if (Helper == None)
        return INDEX_NONE;
    
    for (i = 0; i < AbilitySlots.Length; i++)
    {
        if (AbilitySlots[i].Helper == Helper)
            return i;
    }
    
    return INDEX_NONE;
}

// DK FIX: Find a slot occupied by a helper of the given class (regardless
// of instance). Used by RegisterAbility to replace stale helpers after the
// player respawns instead of stacking duplicate slots.
function int FindSlotByHelperClass(class<Info> HelperClass)
{
    local int i;

    if (HelperClass == None)
        return INDEX_NONE;

    for (i = 0; i < AbilitySlots.Length; i++)
    {
        if (AbilitySlots[i].Helper != None && AbilitySlots[i].HelperClass == HelperClass)
            return i;
    }

    return INDEX_NONE;
}

exec function ReplaceAbilitySlot(int SlotIndex)
{
    ServerReplaceAbilitySlot(SlotIndex);
}

reliable server function ServerReplaceAbilitySlot(int SlotIndex)
{
    if (SlotIndex < 1 || SlotIndex > 4)
    {
        class'ZTMessageManager'.static.SendMinorLoc(self, 'InvalidSlot');
        return;
    }
    
    SlotIndex--;
    
    if (SlotIndex >= AbilitySlots.Length || AbilitySlots[SlotIndex].Helper == None)
    {
        class'ZTMessageManager'.static.SendMinorLoc(self, 'SlotAlreadyEmpty', string(SlotIndex + 1));
        return;
    }
    
    // Destroy the helper
    if (AbilitySlots[SlotIndex].Helper != None)
    {
        AbilitySlots[SlotIndex].Helper.Destroy();
    }
    
    // Clear the slot
    AbilitySlots[SlotIndex].Helper = None;
    AbilitySlots[SlotIndex].AbilityName = "";
    AbilitySlots[SlotIndex].HelperClass = None;
    AbilitySlots[SlotIndex].AbilityIcon = None;
    
    // Update HUD
    ClientUnregisterAbility(SlotIndex);
    
    class'ZTMessageManager'.static.SendImportantLoc(self, 'SlotCleared', string(SlotIndex + 1));
}

exec function ListAbilities()
{
    local int i;
    
    class'ZTMessageManager'.static.SendImportantLoc(self, 'ActiveAbilitiesHeader');
    
    for (i = 0; i < 4; i++)
    {
        if (i < AbilitySlots.Length && AbilitySlots[i].Helper != None)
        {
            class'ZTMessageManager'.static.SendMinorLoc(self, 'SlotStatusFilled', string(i + 1), AbilitySlots[i].AbilityName);
        }
        else
        {
            class'ZTMessageManager'.static.SendMinorLoc(self, 'SlotStatusEmpty', string(i + 1));
        }
    }
}

static function Color MakeColorFromRGB(int R, int G, int B, int A)
{
    local Color NewColor;
    NewColor.R = R;
    NewColor.G = G;
    NewColor.B = B;
    NewColor.A = A;
    return NewColor;
}

function CloseAllSelectionMenus()
{
    if (UpgradeSelectMenu != None && UpgradeSelectMenu.bMenuOpen)
    {
        UpgradeSelectMenu.CloseMenu();
    }
}

function bool IsSelectionMenuOpen()
{
    if (UpgradeSelectMenu != None && UpgradeSelectMenu.bMenuOpen)
        return true;
    
    return false;
}

/** Set HUD scale multiplier. Multiplies the auto-detected resolution scale.
 *  Saved to ZedternalTempered_Local.ini and persists across sessions.
 *
 *  Examples:
 *    DKHudScale 0    -> reset to auto (multiplier 1.0)
 *    DKHudScale 1.2  -> 120% of auto scale
 *    DKHudScale 0.8  -> 80% of auto scale
 *    DKHudScale 1.5  -> 150% of auto scale
 */
exec function DKHudScale(float Scale)
{
    local ZTHudWrapper DKHUD;

    DKHUD = ZTHudWrapper(myHUD);
    if (DKHUD == None)
        return;

    // 0 or negative = reset to auto
    if (Scale <= 0.0f)
        Scale = 1.0f;
    if (Scale > 5.0f)
        Scale = 5.0f;

    DKHUD.HudScaleMultiplier = Scale;

    // Save to client INI so it persists
    class'ZTConfig_HudPreferences'.static.SetHudScaleMultiplier(Scale);

    if (Scale == 1.0f)
    {
        ClientMessage("HUD scale: AUTO (multiplier reset to 1.0x)");
        `log("[DK_HUD] HUD scale: AUTO (multiplier reset to 1.0x)");
    }
    else
    {
        ClientMessage("HUD scale:" @ Scale $ "x multiplier applied to auto scale");
        `log("[DK_HUD] HUD scale:" @ Scale $ "x multiplier applied to auto scale");
    }
}

/** Display detailed HUD scaling info for debugging and tweaking.
 *  Shows detected resolution, tier, auto scale, multiplier, final scale, active cards. */
exec function DKHudInfo()
{
    local ZTHudWrapper DKHUD;
    local string Tier;
    local int ActiveCards;

    DKHUD = ZTHudWrapper(myHUD);
    if (DKHUD == None)
    {
        ClientMessage("DKHudInfo: HUD not available");
        return;
    }

    if (DKHUD.Canvas == None)
    {
        ClientMessage("DKHudInfo: Canvas not available (try during gameplay)");
        return;
    }

    Tier = class'ZTHudWrapper'.static.GetResolutionTierName(DKHUD.Canvas.SizeY);
    ActiveCards = DKHUD.ActiveDisplayCards.Length;

    ClientMessage("=== DK HUD Info ===");
    ClientMessage("Resolution:" @ DKHUD.Canvas.SizeX $ "x" $ DKHUD.Canvas.SizeY @ "(" $ Tier $ ")");
    ClientMessage("Auto Scale:" @ DKHUD.AutoResScale $ "x");
    ClientMessage("Multiplier:" @ DKHUD.HudScaleMultiplier $ "x (DKHudScale to change)");
    ClientMessage("Final Scale:" @ DKHUD.ResScale $ "x");
    ClientMessage("Active Cards:" @ ActiveCards @ "/ Max" @ DKHUD.CardStackMaxCards @ "before compression");
    ClientMessage("Card Shrink:" @ DKHUD.CardStackShrink $ "x (1.0 = no compression)");
    ClientMessage("Stack Limit:" @ (DKHUD.CardStackMaxY * 100.0f) $ "% of screen height");
}

/** Set card stack overflow limit (max screen fraction cards can occupy).
 *  Saved to INI. Default 0.82 = upper 82% of screen.
 *  Example: DKHudCardLimit 0.75 (cards stop at 75% of screen height) */
exec function DKHudCardLimit(float MaxY)
{
    local ZTHudWrapper DKHUD;

    DKHUD = ZTHudWrapper(myHUD);
    if (DKHUD == None)
        return;

    if (MaxY < 0.3f)
        MaxY = 0.3f;
    if (MaxY > 1.0f)
        MaxY = 1.0f;

    DKHUD.CardStackMaxY = MaxY;
    class'ZTConfig_HudPreferences'.static.SetCardStackMaxY(MaxY);
    ClientMessage("Card stack limit set to" @ int(MaxY * 100.0f) $ "% of screen height");
}

/** Force-complete Hollow weapon trials for testing.
 *  DKHollowComplete       -> completes the currently held weapon's trials
 *  DKHollowComplete all   -> completes ALL 128 weapons at once
 *  DKHollowComplete Mosin -> completes weapon matching partial name */
exec function DKHollowComplete(optional string WeaponArg)
{
    local ZTUpgrade_Perk_Hollow_Helper HollowHelper;
    local KFWeapon KFW;
    local string NormName;
    local bool bIsMelee;
    local int i, MatchCount;
    local string CandidateName;

    if (Pawn == None)
    {
        ClientMessage("DKHollowComplete: No pawn.");
        return;
    }

    HollowHelper = class'ZTUpgrade_Perk_Hollow'.static.GetHelper(Pawn);
    if (HollowHelper == None)
    {
        ClientMessage("DKHollowComplete: No Hollow helper (do you have the Hollow perk?)");
        return;
    }

    // "all" -> complete everything
    if (WeaponArg ~= "all")
    {
        HollowHelper.ForceCompleteAll();
        return;
    }

    // No argument -> use currently equipped weapon
    if (WeaponArg == "")
    {
        KFW = KFWeapon(Pawn.Weapon);
        if (KFW == None)
        {
            ClientMessage("DKHollowComplete: No weapon equipped.");
            return;
        }

        NormName = class'ZTUpgrade_Perk_Hollow'.static.NormalizeWeaponName(string(KFW.Class.Name));
        bIsMelee = class'ZTUpgrade_Perk_Hollow'.static.IsMeleeWeapon(KFW);

        if (!class'ZTHollowWeaponData'.static.HasHollowVariant(NormName))
        {
            ClientMessage("DKHollowComplete:" @ NormName @ "has no Hollow variant.");
            return;
        }

        HollowHelper.ForceCompleteWeapon(NormName, bIsMelee);
        return;
    }

    // Partial name search -> find matching weapon in registry
    MatchCount = 0;
    for (i = 0; i < class'ZTHollowWeaponData'.static.GetHollowWeaponCount(); i++)
    {
        CandidateName = class'ZTHollowWeaponData'.static.GetHollowNormName(i);
        if (InStr(Caps(CandidateName), Caps(WeaponArg)) != INDEX_NONE)
        {
            HollowHelper.ForceCompleteWeapon(CandidateName, false);
            MatchCount++;
        }
    }

    if (MatchCount == 0)
        ClientMessage("DKHollowComplete: No weapon matching '" $ WeaponArg $ "' found.");
    else
        ClientMessage("DKHollowComplete: Completed" @ MatchCount @ "matching weapon(s).");
}

// ===================================================================
// TROPHY DROP (Predator Perk)
// Usage:
//   DropTrophy         - List current trophies
//   DropTrophy clot    - Discard one Clot trophy
//   DropTrophy fp      - Discard one Fleshpound trophy
//   DropTrophy all     - Discard all trophies
// ===================================================================

exec function DropTrophy(optional string CategoryArg)
{
    // Route to server - TrophyCount data only exists server-side
    ServerDropTrophy(CategoryArg);
}

reliable server function ServerDropTrophy(string CategoryArg)
{
    local ZTUpgrade_Perk_Predator_Helper H;
    local byte Cat;
    local int Discarded, SetIdx;

    if (Pawn == None)
    {
        ClientMessage("DropTrophy: No pawn.");
        return;
    }

    // Use the perk's robust GetHelper (ChildActors -> DynamicActors -> PRI match)
    H = class'ZTUpgrade_Perk_Predator'.static.GetHelper(Pawn);

    if (H == None)
    {
        ClientMessage("DropTrophy: No Predator helper (do you have the Predator perk?)");
        class'ZTMessageManager'.static.SendMinorLoc(self, 'PredatorNotActive');
        return;
    }

    // No argument = list inventory + sets
    if (CategoryArg == "")
    {
        ClientMessage("Trophies (" $ H.TotalTrophies $ "):" @ H.GetInventoryString());
        ClientMessage("Sets (" $ H.CompletedSetsCount $ "):" @ H.GetCompletedSetsString());
        ClientMessage("Drop trophy: DropTrophy <clot|crawler|gorefast|stalker|bloat|husk|siren|edar|scrake|fp|boss|all>");
        ClientMessage("Drop set: DropTrophy set <swarm|blade|freak|salvage|big|sweep|night|brute|king|apex|wall|legendary>");
        class'ZTMessageManager'.static.SendMinorLoc(self, 'TrophiesInventory', string(H.TotalTrophies), H.GetInventoryString());
        return;
    }

    // "all" = discard all trophies + all sets
    if (CategoryArg ~= "all")
    {
        Discarded = H.DiscardAllTrophies();
        ClientMessage("Discarded all" @ Discarded @ "trophies.");
        class'ZTMessageManager'.static.SendImportantLoc(self, 'DiscardedAllTrophies', string(Discarded));
        return;
    }

    // "set <name>" = discard a completed set
    if (Left(CategoryArg, 4) ~= "set ")
    {
        SetIdx = class'ZTUpgrade_Perk_Predator_Helper'.static.SetFromName(Mid(CategoryArg, 4));
        if (SetIdx == INDEX_NONE)
        {
            ClientMessage("DropTrophy: Unknown set. Use: swarm, blade, freak, salvage, big, sweep, night, brute, king, apex, wall, legendary");
            return;
        }
        if (H.DiscardSet(SetIdx))
            ClientMessage("Discarded set:" @ class'ZTUpgrade_Perk_Predator_Helper'.static.GetSetName(SetIdx) $ ". Remaining sets:" @ H.GetCompletedSetsString());
        else
            ClientMessage(class'ZTUpgrade_Perk_Predator_Helper'.static.GetSetName(SetIdx) @ "is not completed.");
        return;
    }

    // Try trophy category name lookup
    Cat = class'ZTUpgrade_Perk_Predator_Helper'.static.CategoryFromName(CategoryArg);
    if (Cat == 255)
    {
        // Maybe they meant a set name without the "set" prefix
        SetIdx = class'ZTUpgrade_Perk_Predator_Helper'.static.SetFromName(CategoryArg);
        if (SetIdx != INDEX_NONE)
        {
            ClientMessage("To drop a set, use: DropTrophy set" @ CategoryArg);
            return;
        }
        ClientMessage("DropTrophy: Unknown '" $ CategoryArg $ "'. Use: clot, crawler, gorefast, stalker, bloat, husk, siren, edar, scrake, fp, boss, all, or 'set <name>'");
        return;
    }

    if (H.DiscardTrophy(Cat))
    {
        ClientMessage("Dropped" @ class'ZTUpgrade_Perk_Predator_Helper'.static.GetCategoryName(Cat) @ "trophy. Remaining:" @ H.GetInventoryString());
        class'ZTMessageManager'.static.SendMinorLoc(self, 'DroppedTrophy', class'ZTUpgrade_Perk_Predator_Helper'.static.GetCategoryName(Cat));
    }
    else
    {
        ClientMessage("No" @ class'ZTUpgrade_Perk_Predator_Helper'.static.GetCategoryName(Cat) @ "trophy to drop.");
        class'ZTMessageManager'.static.SendMinorLoc(self, 'NoTrophyToDrop', class'ZTUpgrade_Perk_Predator_Helper'.static.GetCategoryName(Cat));
    }
}

/** Cycle the dev stat overlay HUD: Off -> Basic -> Sources. Type 'StatOverlay' in console. */
exec function StatOverlay()
{
    local ZTHudWrapper DKHUD;
    local string ModeName;

    DKHUD = ZTHudWrapper(myHUD);
    if (DKHUD == None)
        return;

    // Cycle: Off (0) -> Basic (1) -> Sources (2) -> Off (0)
    DKHUD.StatOverlayMode = (DKHUD.StatOverlayMode + 1) % 3;

    switch (DKHUD.StatOverlayMode)
    {
        case 0:
            ModeName = "OFF";
            break;
        case 1:
            ModeName = "BASIC (values only)";
            break;
        case 2:
            ModeName = "SOURCES (per-upgrade attribution)";
            break;
    }

    `log("[DK_DEV] Stat overlay:" @ ModeName);
}


// ===================================================================
// DEBUG: Test roguelike upgrade UI - forces 3 Unique-rarity cards
// Respects perk ownership: only shows uniques for perks you own.
// Usage: DKTestUnique           (picks 3 random owned-perk uniques)
//        DKTestUnique PERK_X_X  (forces card 1, picks 2 more from owned)
// ===================================================================
exec function DKTestUnique(optional string ForcedID)
{
    ServerTestUnique(Caps(ForcedID));
}

reliable server function ServerTestUnique(string ForcedID)
{
    local ZTGameInfo_Endless DKGI;
    local ZTGameInfo_Endless_AllWeapons DKGI_AW;
    local ZTRoguelikeUpgradeManager Mgr;
    local ZTPlayerReplicationInfo DKPRI;
    local int i, j, Count;
    local array<string> EligibleIDs;
    local array<string> PickedIDs;
    local string PickedID;
    local int RandIdx;
    local bool bAlreadyPicked;

    // Find the Manager
    DKGI = ZTGameInfo_Endless(WorldInfo.Game);
    if (DKGI != None)
        Mgr = DKGI.RoguelikeManager;
    else
    {
        DKGI_AW = ZTGameInfo_Endless_AllWeapons(WorldInfo.Game);
        if (DKGI_AW != None)
            Mgr = DKGI_AW.RoguelikeManager;
    }

    if (Mgr == None)
    {
        ClientMessage("DKTestUnique: No RoguelikeManager found!");
        return;
    }

    DKPRI = ZTPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKPRI == None)
    {
        ClientMessage("DKTestUnique: No DKPRI!");
        return;
    }

    // Build list of eligible perk uniques (player owns the perk + doesn't have the unique yet)
    for (i = 0; i < Mgr.PerkUniques.Length; i++)
    {
        if (!Mgr.HasPlayerUpgrade(DKPRI, Mgr.PerkUniques[i].UpgradeID)
            && Mgr.HasPlayerPerk(DKPRI, Mgr.PerkUniques[i].RequiredPerkName))
        {
            EligibleIDs.AddItem(Mgr.PerkUniques[i].UpgradeID);
        }
    }

    if (EligibleIDs.Length == 0 && ForcedID == "")
    {
        ClientMessage("DKTestUnique: No eligible uniques! Buy some perks first.");
        return;
    }

    // If ForcedID specified, add it as first pick
    if (ForcedID != "")
    {
        PickedIDs.AddItem(ForcedID);
        `log("[DK_TEST] Forced card 1:" @ ForcedID);
    }

    // Fill remaining slots from eligible pool (up to 3 total)
    Count = 0;
    while (PickedIDs.Length < 3 && Count < 100)
    {
        Count++;
        if (EligibleIDs.Length == 0)
            break;

        RandIdx = Rand(EligibleIDs.Length);
        PickedID = EligibleIDs[RandIdx];

        // Check not already picked
        bAlreadyPicked = false;
        for (j = 0; j < PickedIDs.Length; j++)
        {
            if (PickedIDs[j] == PickedID)
            {
                bAlreadyPicked = true;
                break;
            }
        }

        if (!bAlreadyPicked)
            PickedIDs.AddItem(PickedID);

        EligibleIDs.Remove(RandIdx, 1);
    }

    if (PickedIDs.Length == 0)
    {
        ClientMessage("DKTestUnique: Could not pick any cards!");
        return;
    }

    // Register in manager so OnPlayerSelectedUpgrade can find them
    Mgr.RegisterTestOptions(self, PickedIDs);

    // Send to client via the normal flow
    ClientReceiveUpgradeSelectionStart();
    for (i = 0; i < PickedIDs.Length; i++)
    {
        ClientReceiveUpgradeOption(i, PickedIDs[i], "Test", "Test", "", 5, "");
    }
    ClientShowUpgradeSelection();

    `log("[DK_TEST] Forced" @ PickedIDs.Length @ "unique cards for" @ DKPRI.PlayerName);
    for (i = 0; i < PickedIDs.Length; i++)
    {
        `log("[DK_TEST]   Card" @ i $ ":" @ PickedIDs[i]);
    }
}

// ===================================================================
// COMMAND WHEEL - Trader-only custom command wheel overlay
// Opens a standalone SWF with 10 configurable command slots.
// Player configures slots via INI (ZTConfig_CommandWheel).
// ===================================================================

exec function DKWheel()
{
    local WMGameReplicationInfo WMGRI;

    // If already open, close it
    if (CommandWheelMovie != None)
    {
        CommandWheelMovie.CloseWheel();
        return;
    }

    // Gate: trader must be open
    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None || !WMGRI.bTraderIsOpen)
    {
        ClientMessage("Command wheel is only available during trader time.");
        return;
    }

    if (Pawn == None || !Pawn.IsAliveAndWell())
        return;

    if (bUpgradeMenuOpen)
        return;

    // Create and start the wheel movie
    CommandWheelMovie = new class'ZTCommandWheelMovie';
    CommandWheelMovie.DKPC = self;
    CommandWheelMovie.SetTimingMode(TM_Real);
    CommandWheelMovie.Init(LocalPlayer(Player));
    CommandWheelMovie.OpenWheel(self);
}

// =====================================================================
// =====================================================================
//
//  BULK SYNC SYSTEM ? IMPLEMENTATION  (replaces legacy paged static-array
//                                       replication)
//
//  See ZTBulkSync.uc for architecture overview. Struct definitions and
//  per-roster receive/send state vars are declared at the TOP of this
//  class (UnrealScript requires them before any function bodies).
//  This block contains:
//    - Server-side ServerStartBulkSync entry point
//    - Server-side BulkSyncSendTimer (paces 1 chunk / 0.05s / player)
//    - 11 server-side ServerSendXChunk helpers
//    - 11 reliable client ClientReceiveXChunk RPCs
//    - 1 reliable client ClientBulkSyncComplete handshake
//    - IngestRosterIntoGRI dispatch helper
//
// =====================================================================
// =====================================================================

// =====================================================================
// SERVER ENTRY POINT
// =====================================================================

/** Kick off the bulk sync stream for this player. Called from
 *  ZTGameInfo_Endless.PostLogin (server side) with a small delay so the
 *  net connection has time to settle.
 *
 *  Listen-server local player short-circuit: data is already accessible
 *  via direct memory; skip RPC overhead. Detected via WorldInfo.NetMode
 *  == NM_ListenServer && Player is LocalPlayer. */
function ServerStartBulkSync(WMGameReplicationInfo InGRI, WMGameInfo_Endless InGI)
{
    local int i;

    // Guards
    if (WorldInfo.NetMode == NM_Client)
        return; // bulk sync is server-driven only

    if (InGRI == None || InGI == None)
    {
        `log("[DK_BULKSYNC] ERROR: ServerStartBulkSync called with None GRI or GI");
        return;
    }

    // Listen-server local player has direct memory access; skip RPCs.
    // Dedicated server clients always have a non-None NetConnection.
    if (LocalPlayer(Player) != None)
    {
        `log("[DK_BULKSYNC] Listen-server local player" @ PlayerReplicationInfo.PlayerName @ "-- skipping bulk sync (direct memory access)");
        return;
    }

    // Capture data sources
    BulkSendGRI = InGRI;
    BulkSendGI = InGI;

    // Reset per-roster send state (idempotent for re-entry)
    for (i = 0; i < 12; ++i)
    {
        BulkSendNextIdx[i] = 0;
        BulkSendComplete[i] = 0;
    }
    BulkSendAllDone = false;

    `log("[DK_BULKSYNC] Starting bulk sync to" @ PlayerReplicationInfo.PlayerName
        @ "-- AllowedWeapons:" @ InGRI.AllowedWeaponsList.Length
        @ "TraderWeapons:" @ InGI.KFWeaponDefPath.Length
        @ "PerkUpgrades:" @ InGRI.PerkUpgradesList.Length
        @ "SkillUpgrades:" @ InGRI.SkillUpgradesList.Length
        @ "WeaponUpgrades:" @ InGRI.WeaponUpgradesList.Length
        @ "EquipmentUpgrades:" @ InGRI.EquipmentUpgradesList.Length
        @ "SpecialWaves:" @ InGRI.SpecialWavesList.Length
        @ "ZedBuffs:" @ InGRI.ZedBuffsList.Length);

    // Start paced send timer (replaces any previous run cleanly)
    SetTimer(class'ZTBulkSync'.const.BULK_SEND_INTERVAL, true, 'BulkSyncSendTimer');
}

// =====================================================================
// SERVER SEND TIMER (paces 1 ENTRY per BULK_SEND_INTERVAL)
// =====================================================================
// IMPORTANT: This is the per-entry implementation (Option B1).
//
// Why per-entry: UE3 reliable RPCs with array<T> parameters silently
// drop on the wire ? observed across array<struct{...string...}>,
// array<string>, array<int>, array<byte>, array<float>. Empty-array
// RPCs (TotalCount=0) AND no-arg RPCs (handshake) deliver fine.
// KF2 vanilla never uses array<> params in reliable RPCs ? confirmed
// engine limitation.
//
// Trade-off: 1 RPC per entry = ~1500 RPCs at 40/sec = ~37s for full
// 1500-entry config. Acceptable, runs once at PostLogin.
// =====================================================================

/** Timer callback. Each tick: send the next ENTRY for the next active
 *  roster. When all rosters complete, fire ClientBulkSyncComplete and
 *  stop the timer.
 *
 *  Sends are sequential -- one roster fully completes before the next
 *  starts. Keeps client-side ingest predictable. */
function BulkSyncSendTimer()
{
    local int RosterID;

    // Safety: if GRI/GI vanished mid-stream, abort cleanly.
    if (BulkSendGRI == None || BulkSendGI == None)
    {
        `log("[DK_BULKSYNC] ERROR: GRI/GI vanished mid-send for" @ PlayerReplicationInfo.PlayerName @ "-- aborting");
        ClearTimer('BulkSyncSendTimer');
        return;
    }

    // Find first incomplete roster, send next entry
    for (RosterID = 0; RosterID < 12; ++RosterID)
    {
        if (BulkSendComplete[RosterID] == 0)
        {
            DispatchSendEntry(RosterID);
            return; // one entry per tick
        }
    }

    // All rosters complete -- fire completion handshake + stop timer
    if (!BulkSendAllDone)
    {
        BulkSendAllDone = true;
        ClientBulkSyncComplete();
        `log("[DK_BULKSYNC] Completed bulk sync to" @ PlayerReplicationInfo.PlayerName);
    }
    ClearTimer('BulkSyncSendTimer');
}

/** Dispatch the next entry for the given roster ID. Calls the matching
 *  ServerSendXEntry helper. Marks roster complete when fully sent. */
function DispatchSendEntry(int RosterID)
{
    switch (RosterID)
    {
        case 0:  ServerSendAllowedWeaponEntry();      break;
        case 1:  ServerSendTraderWeaponDefEntry();    break;
        case 2:  ServerSendStartingWeaponEntry();     break;
        case 3:  ServerSendPerkUpgradeEntry();        break;
        case 4:  ServerSendSkillUpgradeEntry();       break;
        case 5:  ServerSendWeaponUpgradeEntry();      break;
        case 6:  ServerSendEquipmentUpgradeEntry();   break;
        case 7:  ServerSendSidearmEntry();            break;
        case 8:  ServerSendGrenadeEntry();            break;
        case 9:  ServerSendSpecialWaveEntry();        break;
        case 10: ServerSendZedBuffEntry();            break;
        case 11: ServerSendSlotCompositionChunk();    break;
        default:
            BulkSendComplete[RosterID] = 1; // unknown roster, skip
            break;
    }
}

// =====================================================================
// PER-ROSTER SEND HELPERS (server -> client one ENTRY at a time)
// =====================================================================
// Each helper:
//   1. Reads BulkSendNextIdx[RosterID] as the next entry index
//   2. If past end of source list, marks roster complete and returns
//   3. Otherwise reads ONE entry's fields, calls the matching
//      ClientReceiveXEntry RPC with primitive args only
//   4. Advances BulkSendNextIdx by 1

function ServerSendAllowedWeaponEntry()
{
    local int Idx, Total;

    Idx = BulkSendNextIdx[0];
    Total = BulkSendGRI.AllowedWeaponsList.Length;

    if (Idx >= Total)
    {
        // Empty-roster case: fire a single TotalCount=0 RPC so client
        // knows expected size, then mark complete.
        if (Total == 0 && BulkRecvExpected[0] == 0)
            ClientReceiveAllowedWeaponEntry(-1, 0, "", 0);
        BulkSendComplete[0] = 1;
        return;
    }

    ClientReceiveAllowedWeaponEntry(
        Idx, Total,
        BulkSendGRI.AllowedWeaponsList[Idx].KFWeaponPath,
        BulkSendGRI.AllowedWeaponsList[Idx].BuyPrice);

    BulkSendNextIdx[0] = Idx + 1;
    if (BulkSendNextIdx[0] >= Total)
        BulkSendComplete[0] = 1;
}

function ServerSendTraderWeaponDefEntry()
{
    local int Idx, Total;

    Idx = BulkSendNextIdx[1];
    Total = BulkSendGI.KFWeaponDefPath.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[1] == 0)
            ClientReceiveTraderWeaponDefEntry(-1, 0, "");
        BulkSendComplete[1] = 1;
        return;
    }

    ClientReceiveTraderWeaponDefEntry(
        Idx, Total,
        BulkSendGI.KFWeaponDefPath[Idx]);

    BulkSendNextIdx[1] = Idx + 1;
    if (BulkSendNextIdx[1] >= Total)
        BulkSendComplete[1] = 1;
}

function ServerSendStartingWeaponEntry()
{
    local int Idx, Total;

    Idx = BulkSendNextIdx[2];
    Total = BulkSendGRI.StartingWeaponsList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[2] == 0)
            ClientReceiveStartingWeaponEntry(-1, 0, "");
        BulkSendComplete[2] = 1;
        return;
    }

    ClientReceiveStartingWeaponEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.StartingWeaponsList[Idx].KFWeapon));

    BulkSendNextIdx[2] = Idx + 1;
    if (BulkSendNextIdx[2] >= Total)
        BulkSendComplete[2] = 1;
}

function ServerSendPerkUpgradeEntry()
{
    local int Idx, Total, PriceVal;

    Idx = BulkSendNextIdx[3];
    Total = BulkSendGRI.PerkUpgradesList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[3] == 0)
            ClientReceivePerkUpgradeEntry(-1, 0, "", 0);
        BulkSendComplete[3] = 1;
        return;
    }

    // Companion: PerkUpgPrice[256] is fixed-size on parent. Beyond 255, default to 0.
    if (Idx < 256)
        PriceVal = BulkSendGRI.PerkUpgPrice[Idx];
    else
        PriceVal = 0;

    ClientReceivePerkUpgradeEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.PerkUpgradesList[Idx].PerkUpgrade),
        PriceVal);

    BulkSendNextIdx[3] = Idx + 1;
    if (BulkSendNextIdx[3] >= Total)
        BulkSendComplete[3] = 1;
}

function ServerSendSkillUpgradeEntry()
{
    local int Idx, Total;
    local byte DeluxeVal;

    Idx = BulkSendNextIdx[4];
    Total = BulkSendGRI.SkillUpgradesList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[4] == 0)
            ClientReceiveSkillUpgradeEntry(-1, 0, "", "", 0);
        BulkSendComplete[4] = 1;
        return;
    }

    if (Idx < 256)
        DeluxeVal = BulkSendGRI.bDeluxeSkillUnlock[Idx];
    else
        DeluxeVal = 0;

    ClientReceiveSkillUpgradeEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.SkillUpgradesList[Idx].SkillUpgrade),
        BulkSendGRI.SkillUpgradesList[Idx].PerkPathName,
        DeluxeVal);

    BulkSendNextIdx[4] = Idx + 1;
    if (BulkSendNextIdx[4] >= Total)
        BulkSendComplete[4] = 1;
}

function ServerSendWeaponUpgradeEntry()
{
    local int Idx, Total;
    local byte IsStaticByte;

    Idx = BulkSendNextIdx[5];
    Total = BulkSendGRI.WeaponUpgradesList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[5] == 0)
            ClientReceiveWeaponUpgradeEntry(-1, 0, "", 0, 0.0f, 0, 0);
        BulkSendComplete[5] = 1;
        return;
    }

    if (BulkSendGRI.WeaponUpgradesList[Idx].bIsStatic)
        IsStaticByte = 1;
    else
        IsStaticByte = 0;

    ClientReceiveWeaponUpgradeEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.WeaponUpgradesList[Idx].WeaponUpgrade),
        BulkSendGRI.WeaponUpgradesList[Idx].PriceUnit,
        BulkSendGRI.WeaponUpgradesList[Idx].PriceMultiplier,
        BulkSendGRI.WeaponUpgradesList[Idx].MaxLevel,
        IsStaticByte);

    BulkSendNextIdx[5] = Idx + 1;
    if (BulkSendNextIdx[5] >= Total)
        BulkSendComplete[5] = 1;
}

function ServerSendEquipmentUpgradeEntry()
{
    local int Idx, Total;

    Idx = BulkSendNextIdx[6];
    Total = BulkSendGRI.EquipmentUpgradesList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[6] == 0)
            ClientReceiveEquipmentUpgradeEntry(-1, 0, "", 0, 0, 0);
        BulkSendComplete[6] = 1;
        return;
    }

    ClientReceiveEquipmentUpgradeEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.EquipmentUpgradesList[Idx].EquipmentUpgrade),
        BulkSendGRI.EquipmentUpgradesList[Idx].BasePrice,
        BulkSendGRI.EquipmentUpgradesList[Idx].MaxPrice,
        BulkSendGRI.EquipmentUpgradesList[Idx].MaxLevel);

    BulkSendNextIdx[6] = Idx + 1;
    if (BulkSendNextIdx[6] >= Total)
        BulkSendComplete[6] = 1;
}

function ServerSendSidearmEntry()
{
    local int Idx, Total;

    Idx = BulkSendNextIdx[7];
    Total = BulkSendGRI.SidearmsList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[7] == 0)
            ClientReceiveSidearmEntry(-1, 0, "", 0);
        BulkSendComplete[7] = 1;
        return;
    }

    ClientReceiveSidearmEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.SidearmsList[Idx].Sidearm),
        BulkSendGRI.SidearmsList[Idx].BuyPrice);

    BulkSendNextIdx[7] = Idx + 1;
    if (BulkSendNextIdx[7] >= Total)
        BulkSendComplete[7] = 1;
}

function ServerSendGrenadeEntry()
{
    local int Idx, Total;

    Idx = BulkSendNextIdx[8];
    Total = BulkSendGRI.GrenadesList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[8] == 0)
            ClientReceiveGrenadeEntry(-1, 0, "");
        BulkSendComplete[8] = 1;
        return;
    }

    ClientReceiveGrenadeEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.GrenadesList[Idx].Grenade));

    BulkSendNextIdx[8] = Idx + 1;
    if (BulkSendNextIdx[8] >= Total)
        BulkSendComplete[8] = 1;
}

function ServerSendSpecialWaveEntry()
{
    local int Idx, Total;

    Idx = BulkSendNextIdx[9];
    Total = BulkSendGRI.SpecialWavesList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[9] == 0)
            ClientReceiveSpecialWaveEntry(-1, 0, "");
        BulkSendComplete[9] = 1;
        return;
    }

    ClientReceiveSpecialWaveEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.SpecialWavesList[Idx].SpecialWave));

    BulkSendNextIdx[9] = Idx + 1;
    if (BulkSendNextIdx[9] >= Total)
        BulkSendComplete[9] = 1;
}

function ServerSendZedBuffEntry()
{
    local int Idx, Total;

    Idx = BulkSendNextIdx[10];
    Total = BulkSendGRI.ZedBuffsList.Length;

    if (Idx >= Total)
    {
        if (Total == 0 && BulkRecvExpected[10] == 0)
            ClientReceiveZedBuffEntry(-1, 0, "");
        BulkSendComplete[10] = 1;
        return;
    }

    ClientReceiveZedBuffEntry(
        Idx, Total,
        class'ZTBulkSync'.static.SafeClassPath(BulkSendGRI.ZedBuffsList[Idx].ZedBuff));

    BulkSendNextIdx[10] = Idx + 1;
    if (BulkSendNextIdx[10] >= Total)
        BulkSendComplete[10] = 1;
}

// ---------------------------------------------------------------------
// Roster 11: SLOT COMPOSITION (per-slot upgrade indices + per-weapon counts)
// ---------------------------------------------------------------------
// This is the data that used to ride the paged static-array replication
// (ZTGameReplicationInfo.SlotUpgIdx_* / WeaponSlotCnt_*) and silently dropped
// at scale, leaving each client with a different partial slice and desynced
// weapon-upgrade counts. Unlike every other roster it is pure bytes, so we
// pack SLOT_CHUNK_BYTES bytes per RPC as a hex string instead of one entry
// per RPC. Source of truth: DKGRI.ServerSlotUpgIdxRecord (slot bytes),
// ServerWeaponSlotCntRecord (per-weapon counts), SlotDataChecksum. These are
// populated + finalized by BOTH ZTGameInfo_Endless and _AllWeapons before any
// PostLogin, so this one shared send path covers both game modes.
function ServerSendSlotCompositionChunk()
{
    local ZTGameReplicationInfo DKGRI;
    local int Chunk, TotalChunks, SlotChunks, CntChunks, NumSlots, NumCnts;
    local int ChunkSz, ChunkBytes, StartByte, j;
    local byte Kind;
    local string PackedHex;

    DKGRI = ZTGameReplicationInfo(BulkSendGRI);
    if (DKGRI == None)
    {
        BulkSendComplete[11] = 1; // nothing to send (wrong GRI type)
        return;
    }

    ChunkSz  = class'ZTBulkSync'.const.SLOT_CHUNK_BYTES;
    NumSlots = Min(DKGRI.ServerSlotUpgIdxRecord.Length, class'ZTGameReplicationInfo'.const.DK_SLOT_PAGES_MAX);
    NumCnts  = Min(DKGRI.ServerWeaponSlotCntRecord.Length, 1024);

    SlotChunks  = (NumSlots + ChunkSz - 1) / ChunkSz;
    CntChunks   = (NumCnts  + ChunkSz - 1) / ChunkSz;
    TotalChunks = SlotChunks + CntChunks;

    // Empty composition (no weapon upgrades at all): one signal RPC carrying
    // the checksum so the client can satisfy IsSlotDataComplete() and finish.
    if (TotalChunks == 0)
    {
        if (BulkRecvExpected[11] == 0)
            ClientReceiveSlotCompositionChunk(-1, 0, 0, 0, 0, "", DKGRI.SlotDataChecksum);
        BulkSendComplete[11] = 1;
        return;
    }

    Chunk = BulkSendNextIdx[11];
    if (Chunk >= TotalChunks)
    {
        BulkSendComplete[11] = 1;
        return;
    }

    if (Chunk < SlotChunks)
    {
        Kind = 0;
        StartByte = Chunk * ChunkSz;
        ChunkBytes = Min(ChunkSz, NumSlots - StartByte);
        for (j = 0; j < ChunkBytes; ++j)
        {
            PackedHex $= class'ZTBulkSync'.static.ByteToHex2(DKGRI.ServerSlotUpgIdxRecord[StartByte + j]);
        }
    }
    else
    {
        Kind = 1;
        StartByte = (Chunk - SlotChunks) * ChunkSz;
        ChunkBytes = Min(ChunkSz, NumCnts - StartByte);
        for (j = 0; j < ChunkBytes; ++j)
        {
            PackedHex $= class'ZTBulkSync'.static.ByteToHex2(DKGRI.ServerWeaponSlotCntRecord[StartByte + j]);
        }
    }

    ClientReceiveSlotCompositionChunk(Chunk, TotalChunks, Kind, StartByte, ChunkBytes, PackedHex, DKGRI.SlotDataChecksum);

    BulkSendNextIdx[11] = Chunk + 1;
    if (BulkSendNextIdx[11] >= TotalChunks)
        BulkSendComplete[11] = 1;
}

// =====================================================================
// CLIENT RPC HANDLERS (one per roster + one completion handshake)
// =====================================================================
// Per-entry implementation (Option B1). Each RPC takes only primitive
// args -- no array<> parameters anywhere -- because UE3 reliable RPCs
// silently drop array<T> payloads on the wire.
//
// Each RPC:
//   1. On first call (BulkRecvExpected[id]==0), pre-sizes recv buffer
//      from TotalCount
//   2. Writes single entry's fields into RecvBuf_X[EntryIdx]
//   3. Increments received count
//   4. When received == expected, calls IngestRosterIntoGRI() to decode
//      and populate XList[]
//   5. Marks the roster complete
//
// Special case: EntryIdx == -1 with TotalCount == 0 is the empty-roster
// signal. Marks the roster complete with no data writes.

reliable client function ClientReceiveAllowedWeaponEntry(int EntryIdx, int TotalCount, string KFWeaponPath, int BuyPrice)
{
    if (BulkRecvExpected[0] == 0)
    {
        BulkRecvExpected[0] = TotalCount;
        RecvBuf_AllowedWeapon.Length = TotalCount;
    }

    // Empty-roster signal: TotalCount=0 means roster is empty, mark complete.
    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[0] == 0)
        {
            BulkRecvComplete[0] = 1;
            IngestRosterIntoGRI(0);
        }
        return;
    }

    if (EntryIdx < RecvBuf_AllowedWeapon.Length)
    {
        RecvBuf_AllowedWeapon[EntryIdx].KFWeaponPath = KFWeaponPath;
        RecvBuf_AllowedWeapon[EntryIdx].BuyPrice     = BuyPrice;
    }
    BulkRecvReceived[0] += 1;

    if (BulkRecvReceived[0] >= BulkRecvExpected[0] && BulkRecvComplete[0] == 0)
    {
        BulkRecvComplete[0] = 1;
        IngestRosterIntoGRI(0);
    }
}

reliable client function ClientReceiveTraderWeaponDefEntry(int EntryIdx, int TotalCount, string WeapDefPath)
{
    if (BulkRecvExpected[1] == 0)
    {
        BulkRecvExpected[1] = TotalCount;
        RecvBuf_TraderWeaponDef.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[1] == 0)
        {
            BulkRecvComplete[1] = 1;
            IngestRosterIntoGRI(1);
        }
        return;
    }

    if (EntryIdx < RecvBuf_TraderWeaponDef.Length)
        RecvBuf_TraderWeaponDef[EntryIdx].WeapDefPath = WeapDefPath;
    BulkRecvReceived[1] += 1;

    if (BulkRecvReceived[1] >= BulkRecvExpected[1] && BulkRecvComplete[1] == 0)
    {
        BulkRecvComplete[1] = 1;
        IngestRosterIntoGRI(1);
    }
}

reliable client function ClientReceiveStartingWeaponEntry(int EntryIdx, int TotalCount, string KFWeaponPath)
{
    if (BulkRecvExpected[2] == 0)
    {
        BulkRecvExpected[2] = TotalCount;
        RecvBuf_StartingWeapon.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[2] == 0)
        {
            BulkRecvComplete[2] = 1;
            IngestRosterIntoGRI(2);
        }
        return;
    }

    if (EntryIdx < RecvBuf_StartingWeapon.Length)
        RecvBuf_StartingWeapon[EntryIdx].KFWeaponPath = KFWeaponPath;
    BulkRecvReceived[2] += 1;

    if (BulkRecvReceived[2] >= BulkRecvExpected[2] && BulkRecvComplete[2] == 0)
    {
        BulkRecvComplete[2] = 1;
        IngestRosterIntoGRI(2);
    }
}

reliable client function ClientReceivePerkUpgradeEntry(int EntryIdx, int TotalCount, string PerkPathName, int PriceInt)
{
    if (BulkRecvExpected[3] == 0)
    {
        BulkRecvExpected[3] = TotalCount;
        RecvBuf_PerkUpgrade.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[3] == 0)
        {
            BulkRecvComplete[3] = 1;
            IngestRosterIntoGRI(3);
        }
        return;
    }

    if (EntryIdx < RecvBuf_PerkUpgrade.Length)
    {
        RecvBuf_PerkUpgrade[EntryIdx].PerkPathName = PerkPathName;
        RecvBuf_PerkUpgrade[EntryIdx].PriceInt     = PriceInt;
    }
    BulkRecvReceived[3] += 1;

    if (BulkRecvReceived[3] >= BulkRecvExpected[3] && BulkRecvComplete[3] == 0)
    {
        BulkRecvComplete[3] = 1;
        IngestRosterIntoGRI(3);
    }
}

reliable client function ClientReceiveSkillUpgradeEntry(int EntryIdx, int TotalCount, string SkillPathName, string PerkPathName, byte bDeluxeUnlock)
{
    if (BulkRecvExpected[4] == 0)
    {
        BulkRecvExpected[4] = TotalCount;
        RecvBuf_SkillUpgrade.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[4] == 0)
        {
            BulkRecvComplete[4] = 1;
            IngestRosterIntoGRI(4);
        }
        return;
    }

    if (EntryIdx < RecvBuf_SkillUpgrade.Length)
    {
        RecvBuf_SkillUpgrade[EntryIdx].SkillPathName = SkillPathName;
        RecvBuf_SkillUpgrade[EntryIdx].PerkPathName  = PerkPathName;
        RecvBuf_SkillUpgrade[EntryIdx].bDeluxeUnlock = bDeluxeUnlock;
    }
    BulkRecvReceived[4] += 1;

    if (BulkRecvReceived[4] >= BulkRecvExpected[4] && BulkRecvComplete[4] == 0)
    {
        BulkRecvComplete[4] = 1;
        IngestRosterIntoGRI(4);
    }
}

reliable client function ClientReceiveWeaponUpgradeEntry(int EntryIdx, int TotalCount, string WeaponUpgPathName, int PriceUnit, float PriceMultiplier, int MaxLevel, byte bIsStaticByte)
{
    if (BulkRecvExpected[5] == 0)
    {
        BulkRecvExpected[5] = TotalCount;
        RecvBuf_WeaponUpgrade.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[5] == 0)
        {
            BulkRecvComplete[5] = 1;
            IngestRosterIntoGRI(5);
        }
        return;
    }

    if (EntryIdx < RecvBuf_WeaponUpgrade.Length)
    {
        RecvBuf_WeaponUpgrade[EntryIdx].WeaponUpgPathName = WeaponUpgPathName;
        RecvBuf_WeaponUpgrade[EntryIdx].PriceUnit         = PriceUnit;
        RecvBuf_WeaponUpgrade[EntryIdx].PriceMultiplier   = PriceMultiplier;
        RecvBuf_WeaponUpgrade[EntryIdx].MaxLevel          = MaxLevel;
        RecvBuf_WeaponUpgrade[EntryIdx].bIsStatic         = (bIsStaticByte != 0);
    }
    BulkRecvReceived[5] += 1;

    if (BulkRecvReceived[5] >= BulkRecvExpected[5] && BulkRecvComplete[5] == 0)
    {
        BulkRecvComplete[5] = 1;
        IngestRosterIntoGRI(5);
    }
}

reliable client function ClientReceiveEquipmentUpgradeEntry(int EntryIdx, int TotalCount, string EquipmentPathName, int BasePrice, int MaxPrice, byte MaxLevel)
{
    if (BulkRecvExpected[6] == 0)
    {
        BulkRecvExpected[6] = TotalCount;
        RecvBuf_EquipmentUpgrade.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[6] == 0)
        {
            BulkRecvComplete[6] = 1;
            IngestRosterIntoGRI(6);
        }
        return;
    }

    if (EntryIdx < RecvBuf_EquipmentUpgrade.Length)
    {
        RecvBuf_EquipmentUpgrade[EntryIdx].EquipmentPathName = EquipmentPathName;
        RecvBuf_EquipmentUpgrade[EntryIdx].BasePrice         = BasePrice;
        RecvBuf_EquipmentUpgrade[EntryIdx].MaxPrice          = MaxPrice;
        RecvBuf_EquipmentUpgrade[EntryIdx].MaxLevel          = MaxLevel;
    }
    BulkRecvReceived[6] += 1;

    if (BulkRecvReceived[6] >= BulkRecvExpected[6] && BulkRecvComplete[6] == 0)
    {
        BulkRecvComplete[6] = 1;
        IngestRosterIntoGRI(6);
    }
}

reliable client function ClientReceiveSidearmEntry(int EntryIdx, int TotalCount, string WeaponPathName, int BuyPrice)
{
    if (BulkRecvExpected[7] == 0)
    {
        BulkRecvExpected[7] = TotalCount;
        RecvBuf_Sidearm.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[7] == 0)
        {
            BulkRecvComplete[7] = 1;
            IngestRosterIntoGRI(7);
        }
        return;
    }

    if (EntryIdx < RecvBuf_Sidearm.Length)
    {
        RecvBuf_Sidearm[EntryIdx].WeaponPathName = WeaponPathName;
        RecvBuf_Sidearm[EntryIdx].BuyPrice       = BuyPrice;
    }
    BulkRecvReceived[7] += 1;

    if (BulkRecvReceived[7] >= BulkRecvExpected[7] && BulkRecvComplete[7] == 0)
    {
        BulkRecvComplete[7] = 1;
        IngestRosterIntoGRI(7);
    }
}

reliable client function ClientReceiveGrenadeEntry(int EntryIdx, int TotalCount, string GrenadePathName)
{
    if (BulkRecvExpected[8] == 0)
    {
        BulkRecvExpected[8] = TotalCount;
        RecvBuf_Grenade.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[8] == 0)
        {
            BulkRecvComplete[8] = 1;
            IngestRosterIntoGRI(8);
        }
        return;
    }

    if (EntryIdx < RecvBuf_Grenade.Length)
        RecvBuf_Grenade[EntryIdx].GrenadePathName = GrenadePathName;
    BulkRecvReceived[8] += 1;

    if (BulkRecvReceived[8] >= BulkRecvExpected[8] && BulkRecvComplete[8] == 0)
    {
        BulkRecvComplete[8] = 1;
        IngestRosterIntoGRI(8);
    }
}

reliable client function ClientReceiveSpecialWaveEntry(int EntryIdx, int TotalCount, string SpecialWavePathName)
{
    if (BulkRecvExpected[9] == 0)
    {
        BulkRecvExpected[9] = TotalCount;
        RecvBuf_SpecialWave.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[9] == 0)
        {
            BulkRecvComplete[9] = 1;
            IngestRosterIntoGRI(9);
        }
        return;
    }

    if (EntryIdx < RecvBuf_SpecialWave.Length)
        RecvBuf_SpecialWave[EntryIdx].SpecialWavePathName = SpecialWavePathName;
    BulkRecvReceived[9] += 1;

    if (BulkRecvReceived[9] >= BulkRecvExpected[9] && BulkRecvComplete[9] == 0)
    {
        BulkRecvComplete[9] = 1;
        IngestRosterIntoGRI(9);
    }
}

reliable client function ClientReceiveZedBuffEntry(int EntryIdx, int TotalCount, string ZedBuffPathName)
{
    if (BulkRecvExpected[10] == 0)
    {
        BulkRecvExpected[10] = TotalCount;
        RecvBuf_ZedBuff.Length = TotalCount;
    }

    if (EntryIdx < 0 || TotalCount == 0)
    {
        if (BulkRecvComplete[10] == 0)
        {
            BulkRecvComplete[10] = 1;
            IngestRosterIntoGRI(10);
        }
        return;
    }

    if (EntryIdx < RecvBuf_ZedBuff.Length)
        RecvBuf_ZedBuff[EntryIdx].ZedBuffPathName = ZedBuffPathName;
    BulkRecvReceived[10] += 1;

    if (BulkRecvReceived[10] >= BulkRecvExpected[10] && BulkRecvComplete[10] == 0)
    {
        BulkRecvComplete[10] = 1;
        IngestRosterIntoGRI(10);
    }
}

// Roster 11: slot composition. Each RPC carries a hex-packed run of bytes
// (Kind 0 = per-slot upgrade indices, Kind 1 = per-weapon counts) written
// straight into the GRI's paged arrays via the now-simulated setters. No
// RecvBuf needed -- decode goes directly to its final home. The checksum is
// applied on completion; IsSlotDataComplete() then validates the whole set
// (sum of bytes + 7 == checksum), so a dropped chunk can never falsely pass.
reliable client function ClientReceiveSlotCompositionChunk(int ChunkIdx, int TotalChunks, byte Kind, int StartByte, int NumBytesInChunk, string PackedHex, int Checksum)
{
    local ZTGameReplicationInfo DKGRI;
    local int j, hi, lo, b;

    DKGRI = ZTGameReplicationInfo(WorldInfo.GRI);
    if (DKGRI == None)
    {
        `log("[DK_BULKSYNC] ERROR: SlotComposition chunk but GRI is not ZTGameReplicationInfo");
        return;
    }

    if (BulkRecvExpected[11] == 0)
        BulkRecvExpected[11] = TotalChunks;

    // Empty-composition signal: no bytes, just set the checksum and finish.
    if (ChunkIdx < 0 || TotalChunks == 0)
    {
        if (BulkRecvComplete[11] == 0)
        {
            DKGRI.SlotDataChecksum = Checksum;
            BulkRecvComplete[11] = 1;
            IngestRosterIntoGRI(11);
        }
        return;
    }

    // Decode this chunk's bytes straight into the GRI paged arrays.
    for (j = 0; j < NumBytesInChunk; ++j)
    {
        hi = class'ZTBulkSync'.static.HexCharToInt(Mid(PackedHex, j * 2, 1));
        lo = class'ZTBulkSync'.static.HexCharToInt(Mid(PackedHex, j * 2 + 1, 1));
        b = hi * 16 + lo;

        if (Kind == 0)
            DKGRI.SetSlotUpgIdx(StartByte + j, byte(b));
        else
            DKGRI.SetWeaponSlotCnt(StartByte + j, byte(b));
    }

    BulkRecvReceived[11] += 1;

    if (BulkRecvReceived[11] >= BulkRecvExpected[11] && BulkRecvComplete[11] == 0)
    {
        DKGRI.SlotDataChecksum = Checksum;
        BulkRecvComplete[11] = 1;
        IngestRosterIntoGRI(11);
    }
}

/** Server-side completion handshake. Fired after the last chunk for the
 *  last roster has been sent. Client side: all rosters should already
 *  be ingested (last chunk's RPC handler runs ingest). This RPC is the
 *  final "all done" signal that flips bAllDataSynced and unblocks the
 *  GenerateDataFromSyncData flow. */
reliable client function ClientBulkSyncComplete()
{
    local ZTGameReplicationInfo DKGRI;

    BulkRecvAllDone = true;

    DKGRI = ZTGameReplicationInfo(WorldInfo.GRI);
    if (DKGRI != None)
    {
        DKGRI.OnBulkSyncComplete();
        `log("[DK_BULKSYNC] Client received all rosters; bAllDataSynced flipped");
    }
    else
    {
        `log("[DK_BULKSYNC] ERROR: Client received completion but GRI is not ZTGameReplicationInfo");
    }
}

// ===================================================================
// SLOT-COMPOSITION RESYNC  (self-heal for the "empty weapon upgrades" bug)
// ===================================================================
// Roster 11 (BR_SlotComposition) carries the per-slot upgrade indices +
// per-weapon counts the UPG menu needs, and rides the reliable bulk-sync
// stream ONLY (it was removed from native replication). If it never completes
// for a client (a dropped chunk or a transient server-send stall), then
// ZTGameReplicationInfo.IsSlotDataComplete() stays false forever,
// GenerateWeaponUpgrades() is skipped, and the trader shows no weapon
// upgrades. ZTGameReplicationInfo.SyncTimer drives RequestSlotResync()
// (client side) to re-stream just roster 11; its existing generation loop
// then finishes the build once the bytes land.

/** CLIENT: reset our roster-11 receive counters and ask the server to
 *  re-stream the slot composition. Idempotent -- chunks write GRI bytes by
 *  absolute index, so a re-send overwrites them in place. */
simulated function RequestSlotResync()
{
    BulkRecvExpected[11] = 0;
    BulkRecvReceived[11] = 0;
    BulkRecvComplete[11] = 0;
    ServerRequestSlotResync();
}

/** SERVER: re-arm roster 11 and restart the paced send timer. The timer
 *  skips already-complete rosters 0-10 and re-streams only slot composition.
 *  No-op if bulk sync was never started for this player (e.g. a listen-server
 *  local player with direct memory access). */
reliable server function ServerRequestSlotResync()
{
    if (WorldInfo.NetMode == NM_Client)
        return;

    if (BulkSendGRI == None || BulkSendGI == None)
        return; // bulk sync never started; nothing to resend

    BulkSendNextIdx[11]  = 0;
    BulkSendComplete[11] = 0;
    BulkSendAllDone      = false;

    SetTimer(class'ZTBulkSync'.const.BULK_SEND_INTERVAL, true, 'BulkSyncSendTimer');
    `log("[DK_BULKSYNC] Slot resync requested by" @ PlayerReplicationInfo.PlayerName @ "-- re-streaming roster 11");
}

// =====================================================================
// LOCAL INGEST IMPLEMENTATIONS  (was on DKGRI; moved here because UE3
//                                forbids cross-class struct references
//                                in function parameter lists)
// =====================================================================
// Each ingest:
//   1. Resizes target list on DKGRI to RecvBuf length
//   2. For each entry: DynamicLoadObject the path string, write to DKGRI
//   3. Sets companion data (PerkUpgPrice, bDeluxeSkillUnlock, etc.)
//   4. Sets bDone=true on the list entry
//   5. Flips per-block sync flag(s) on DKGRI
//
// Note: GetItemName() is a simulated instance function inherited on the
// GRI. Called as DKGRI.GetItemName() to satisfy UE3 method resolution.

simulated function IngestAllowedWeaponRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_AllowedWeapon.Length == 0)
        return;

    DKGRI.AllowedWeaponsList.Length = RecvBuf_AllowedWeapon.Length;
    for (i = 0; i < RecvBuf_AllowedWeapon.Length; ++i)
    {
        DKGRI.AllowedWeaponsList[i].KFWeaponPath = RecvBuf_AllowedWeapon[i].KFWeaponPath;
        DKGRI.AllowedWeaponsList[i].WeaponName = name(DKGRI.GetItemName(RecvBuf_AllowedWeapon[i].KFWeaponPath));
        DKGRI.AllowedWeaponsList[i].BuyPrice = RecvBuf_AllowedWeapon[i].BuyPrice;
        DKGRI.AllowedWeaponsList[i].bDone = true;
    }

    DKGRI.bAllowedWeaponsSynced_A = true;
    DKGRI.bAllowedWeaponsSynced_B = true;
    DKGRI.bAllowedWeaponsSynced_C = true;
    DKGRI.bAllowedWeaponsSynced_D = true;
    DKGRI.NumberOfAllowedWeapons = RecvBuf_AllowedWeapon.Length;

    `log("[DK_BULKSYNC] Ingested AllowedWeapons:" @ RecvBuf_AllowedWeapon.Length);
}

simulated function IngestTraderWeaponDefRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<KFWeaponDefinition> WD;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_TraderWeaponDef.Length == 0)
        return;

    if (DKGRI.TraderItems == None)
    {
        DKGRI.TraderItems = new class'WMGFxObject_TraderItems';
    }
    DKGRI.TraderItems.SaleItems.Length = RecvBuf_TraderWeaponDef.Length;

    for (i = 0; i < RecvBuf_TraderWeaponDef.Length; ++i)
    {
        if (RecvBuf_TraderWeaponDef[i].WeapDefPath == "")
            continue;

        WD = class<KFWeaponDefinition>(DynamicLoadObject(RecvBuf_TraderWeaponDef[i].WeapDefPath, class'Class'));
        if (WD == None)
        {
            `log("[DK_BULKSYNC] WARNING: Failed to load WeapDef [" $ i $ "]" @ RecvBuf_TraderWeaponDef[i].WeapDefPath);
        }
        DKGRI.TraderItems.SaleItems[i].WeaponDef = WD;
        DKGRI.TraderItems.SaleItems[i].ItemID = i;
    }

    DKGRI.bTraderWeaponsSynced_A = true;
    DKGRI.bTraderWeaponsSynced_B = true;
    DKGRI.bTraderWeaponsSynced_C = true;
    DKGRI.bTraderWeaponsSynced_D = true;
    DKGRI.NumberOfTraderWeapons = RecvBuf_TraderWeaponDef.Length;

    `log("[DK_BULKSYNC] Ingested TraderWeaponDefs:" @ RecvBuf_TraderWeaponDef.Length);
}

simulated function IngestStartingWeaponRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<KFWeapon> KFW;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_StartingWeapon.Length == 0)
        return;

    DKGRI.StartingWeaponsList.Length = RecvBuf_StartingWeapon.Length;
    for (i = 0; i < RecvBuf_StartingWeapon.Length; ++i)
    {
        if (RecvBuf_StartingWeapon[i].KFWeaponPath == "")
        {
            DKGRI.StartingWeaponsList[i].KFWeapon = None;
            DKGRI.StartingWeaponsList[i].bDone = true;
            continue;
        }

        KFW = class<KFWeapon>(DynamicLoadObject(RecvBuf_StartingWeapon[i].KFWeaponPath, class'Class'));
        if (KFW == None)
        {
            `log("[DK_BULKSYNC] WARNING: Failed to load StartingWeapon [" $ i $ "]" @ RecvBuf_StartingWeapon[i].KFWeaponPath);
        }
        DKGRI.StartingWeaponsList[i].KFWeapon = KFW;
        DKGRI.StartingWeaponsList[i].bDone = true;
    }

    DKGRI.bStartingWeaponsSynced = true;
    DKGRI.NumberOfStartingWeapons = RecvBuf_StartingWeapon.Length;

    `log("[DK_BULKSYNC] Ingested StartingWeapons:" @ RecvBuf_StartingWeapon.Length);
}

simulated function IngestPerkUpgradeRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<WMUpgrade_Perk> Loaded;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_PerkUpgrade.Length == 0)
        return;

    DKGRI.PerkUpgradesList.Length = RecvBuf_PerkUpgrade.Length;
    for (i = 0; i < RecvBuf_PerkUpgrade.Length; ++i)
    {
        if (RecvBuf_PerkUpgrade[i].PerkPathName == "")
        {
            DKGRI.PerkUpgradesList[i].PerkUpgrade = None;
            DKGRI.PerkUpgradesList[i].bDone = true;
        }
        else
        {
            Loaded = class<WMUpgrade_Perk>(DynamicLoadObject(RecvBuf_PerkUpgrade[i].PerkPathName, class'Class'));
            if (Loaded == None)
                `log("[DK_BULKSYNC] WARNING: Failed to load PerkUpgrade [" $ i $ "]" @ RecvBuf_PerkUpgrade[i].PerkPathName);
            DKGRI.PerkUpgradesList[i].PerkUpgrade = Loaded;
            DKGRI.PerkUpgradesList[i].bDone = true;
        }

        // Companion: PerkUpgPrice is fixed [256] on parent.
        if (i < 256)
            DKGRI.PerkUpgPrice[i] = RecvBuf_PerkUpgrade[i].PriceInt;
    }

    DKGRI.bPerkUpgradesSynced = true;
    DKGRI.NumberOfPerkUpgrades = RecvBuf_PerkUpgrade.Length;

    `log("[DK_BULKSYNC] Ingested PerkUpgrades:" @ RecvBuf_PerkUpgrade.Length);
}

simulated function IngestSkillUpgradeRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<WMUpgrade_Skill> Loaded;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_SkillUpgrade.Length == 0)
        return;

    DKGRI.SkillUpgradesList.Length = RecvBuf_SkillUpgrade.Length;
    for (i = 0; i < RecvBuf_SkillUpgrade.Length; ++i)
    {
        if (RecvBuf_SkillUpgrade[i].SkillPathName == "")
        {
            DKGRI.SkillUpgradesList[i].SkillUpgrade = None;
        }
        else
        {
            Loaded = class<WMUpgrade_Skill>(DynamicLoadObject(RecvBuf_SkillUpgrade[i].SkillPathName, class'Class'));
            if (Loaded == None)
                `log("[DK_BULKSYNC] WARNING: Failed to load SkillUpgrade [" $ i $ "]" @ RecvBuf_SkillUpgrade[i].SkillPathName);
            DKGRI.SkillUpgradesList[i].SkillUpgrade = Loaded;
        }
        DKGRI.SkillUpgradesList[i].PerkPathName = RecvBuf_SkillUpgrade[i].PerkPathName;
        DKGRI.SkillUpgradesList[i].bDone = true;

        // Companion: bDeluxeSkillUnlock is fixed [256] on parent.
        if (i < 256)
            DKGRI.bDeluxeSkillUnlock[i] = RecvBuf_SkillUpgrade[i].bDeluxeUnlock;
    }

    DKGRI.bSkillUpgradesSynced_A = true;
    DKGRI.bSkillUpgradesSynced_B = true;
    DKGRI.bSkillUpgradesSynced_C = true;
    DKGRI.bSkillUpgradesSynced_D = true;
    DKGRI.NumberOfSkillUpgrades = RecvBuf_SkillUpgrade.Length;

    `log("[DK_BULKSYNC] Ingested SkillUpgrades:" @ RecvBuf_SkillUpgrade.Length);
}

simulated function IngestWeaponUpgradeRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<WMUpgrade_Weapon> Loaded;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_WeaponUpgrade.Length == 0)
        return;

    DKGRI.WeaponUpgradesList.Length = RecvBuf_WeaponUpgrade.Length;
    for (i = 0; i < RecvBuf_WeaponUpgrade.Length; ++i)
    {
        DKGRI.WeaponUpgradesList[i].PriceUnit       = RecvBuf_WeaponUpgrade[i].PriceUnit;
        DKGRI.WeaponUpgradesList[i].PriceMultiplier = RecvBuf_WeaponUpgrade[i].PriceMultiplier;
        DKGRI.WeaponUpgradesList[i].MaxLevel        = RecvBuf_WeaponUpgrade[i].MaxLevel;
        DKGRI.WeaponUpgradesList[i].bIsStatic       = RecvBuf_WeaponUpgrade[i].bIsStatic;

        if (RecvBuf_WeaponUpgrade[i].WeaponUpgPathName == "")
        {
            DKGRI.WeaponUpgradesList[i].WeaponUpgrade = None;
        }
        else
        {
            Loaded = class<WMUpgrade_Weapon>(DynamicLoadObject(RecvBuf_WeaponUpgrade[i].WeaponUpgPathName, class'Class'));
            if (Loaded == None)
                `log("[DK_BULKSYNC] WARNING: Failed to load WeaponUpgrade [" $ i $ "]" @ RecvBuf_WeaponUpgrade[i].WeaponUpgPathName);
            DKGRI.WeaponUpgradesList[i].WeaponUpgrade = Loaded;
        }
        DKGRI.WeaponUpgradesList[i].bDone = true;
    }

    DKGRI.bWeaponUpgradesSynced = true;
    DKGRI.NumberOfWeaponUpgrades = RecvBuf_WeaponUpgrade.Length;

    `log("[DK_BULKSYNC] Ingested WeaponUpgrades:" @ RecvBuf_WeaponUpgrade.Length);
}

simulated function IngestEquipmentUpgradeRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<WMUpgrade_Equipment> Loaded;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_EquipmentUpgrade.Length == 0)
        return;

    DKGRI.EquipmentUpgradesList.Length = RecvBuf_EquipmentUpgrade.Length;
    for (i = 0; i < RecvBuf_EquipmentUpgrade.Length; ++i)
    {
        DKGRI.EquipmentUpgradesList[i].BasePrice = RecvBuf_EquipmentUpgrade[i].BasePrice;
        DKGRI.EquipmentUpgradesList[i].MaxPrice  = RecvBuf_EquipmentUpgrade[i].MaxPrice;
        DKGRI.EquipmentUpgradesList[i].MaxLevel  = RecvBuf_EquipmentUpgrade[i].MaxLevel;

        if (RecvBuf_EquipmentUpgrade[i].EquipmentPathName == "")
        {
            DKGRI.EquipmentUpgradesList[i].EquipmentUpgrade = None;
        }
        else
        {
            Loaded = class<WMUpgrade_Equipment>(DynamicLoadObject(RecvBuf_EquipmentUpgrade[i].EquipmentPathName, class'Class'));
            if (Loaded == None)
                `log("[DK_BULKSYNC] WARNING: Failed to load EquipmentUpgrade [" $ i $ "]" @ RecvBuf_EquipmentUpgrade[i].EquipmentPathName);
            DKGRI.EquipmentUpgradesList[i].EquipmentUpgrade = Loaded;
        }
        DKGRI.EquipmentUpgradesList[i].bDone = true;
    }

    DKGRI.bEquipmentUpgradesSynced = true;
    DKGRI.NumberOfEquipmentUpgrades = RecvBuf_EquipmentUpgrade.Length;

    `log("[DK_BULKSYNC] Ingested EquipmentUpgrades:" @ RecvBuf_EquipmentUpgrade.Length);
}

simulated function IngestSidearmRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<KFWeaponDefinition> Loaded;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_Sidearm.Length == 0)
        return;

    DKGRI.SidearmsList.Length = RecvBuf_Sidearm.Length;
    for (i = 0; i < RecvBuf_Sidearm.Length; ++i)
    {
        DKGRI.SidearmsList[i].BuyPrice = RecvBuf_Sidearm[i].BuyPrice;

        if (RecvBuf_Sidearm[i].WeaponPathName == "")
        {
            DKGRI.SidearmsList[i].Sidearm = None;
        }
        else
        {
            Loaded = class<KFWeaponDefinition>(DynamicLoadObject(RecvBuf_Sidearm[i].WeaponPathName, class'Class'));
            if (Loaded == None)
                `log("[DK_BULKSYNC] WARNING: Failed to load Sidearm [" $ i $ "]" @ RecvBuf_Sidearm[i].WeaponPathName);
            DKGRI.SidearmsList[i].Sidearm = Loaded;
        }
        DKGRI.SidearmsList[i].bDone = true;
    }

    DKGRI.bSidearmItemsSynced = true;
    DKGRI.NumberOfSidearmItems = RecvBuf_Sidearm.Length;

    `log("[DK_BULKSYNC] Ingested Sidearms:" @ RecvBuf_Sidearm.Length);
}

simulated function IngestGrenadeRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<KFWeaponDefinition> Loaded;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_Grenade.Length == 0)
        return;

    DKGRI.GrenadesList.Length = RecvBuf_Grenade.Length;
    for (i = 0; i < RecvBuf_Grenade.Length; ++i)
    {
        if (RecvBuf_Grenade[i].GrenadePathName == "")
        {
            DKGRI.GrenadesList[i].Grenade = None;
        }
        else
        {
            Loaded = class<KFWeaponDefinition>(DynamicLoadObject(RecvBuf_Grenade[i].GrenadePathName, class'Class'));
            if (Loaded == None)
                `log("[DK_BULKSYNC] WARNING: Failed to load Grenade [" $ i $ "]" @ RecvBuf_Grenade[i].GrenadePathName);
            DKGRI.GrenadesList[i].Grenade = Loaded;
        }
        DKGRI.GrenadesList[i].bDone = true;
    }

    DKGRI.bGrenadeItemsSynced = true;
    DKGRI.NumberOfGrenadeItems = RecvBuf_Grenade.Length;

    `log("[DK_BULKSYNC] Ingested Grenades:" @ RecvBuf_Grenade.Length);
}

simulated function IngestSpecialWaveRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<WMSpecialWave> Loaded;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_SpecialWave.Length == 0)
        return;

    DKGRI.SpecialWavesList.Length = RecvBuf_SpecialWave.Length;
    for (i = 0; i < RecvBuf_SpecialWave.Length; ++i)
    {
        if (RecvBuf_SpecialWave[i].SpecialWavePathName == "")
        {
            DKGRI.SpecialWavesList[i].SpecialWave = None;
        }
        else
        {
            Loaded = class<WMSpecialWave>(DynamicLoadObject(RecvBuf_SpecialWave[i].SpecialWavePathName, class'Class'));
            if (Loaded == None)
                `log("[DK_BULKSYNC] WARNING: Failed to load SpecialWave [" $ i $ "]" @ RecvBuf_SpecialWave[i].SpecialWavePathName);
            DKGRI.SpecialWavesList[i].SpecialWave = Loaded;
        }
        DKGRI.SpecialWavesList[i].bDone = true;
    }

    DKGRI.bSpecialWavesSynced = true;
    DKGRI.NumberOfSpecialWaves = RecvBuf_SpecialWave.Length;

    `log("[DK_BULKSYNC] Ingested SpecialWaves:" @ RecvBuf_SpecialWave.Length);
}

simulated function IngestZedBuffRoster(ZTGameReplicationInfo DKGRI)
{
    local int i;
    local class<WMZedBuff> Loaded;

    // Step 1 safety: don't wipe legacy-populated list with empty bulk-sync data
    if (RecvBuf_ZedBuff.Length == 0)
        return;

    DKGRI.ZedBuffsList.Length = RecvBuf_ZedBuff.Length;
    for (i = 0; i < RecvBuf_ZedBuff.Length; ++i)
    {
        if (RecvBuf_ZedBuff[i].ZedBuffPathName == "")
        {
            DKGRI.ZedBuffsList[i].ZedBuff = None;
        }
        else
        {
            Loaded = class<WMZedBuff>(DynamicLoadObject(RecvBuf_ZedBuff[i].ZedBuffPathName, class'Class'));
            if (Loaded == None)
                `log("[DK_BULKSYNC] WARNING: Failed to load ZedBuff [" $ i $ "]" @ RecvBuf_ZedBuff[i].ZedBuffPathName);
            DKGRI.ZedBuffsList[i].ZedBuff = Loaded;
        }
        DKGRI.ZedBuffsList[i].bDone = true;
    }

    DKGRI.bZedBuffsSynced = true;
    DKGRI.NumberOfZedBuffs = RecvBuf_ZedBuff.Length;

    `log("[DK_BULKSYNC] Ingested ZedBuffs:" @ RecvBuf_ZedBuff.Length);
}

// =====================================================================
// INGEST DISPATCH (client side, called after each roster's chunks complete)
// =====================================================================

/** Hand the completed roster's recv buffer to the local ingest helper.
 *  Each helper writes directly to DKGRI fields. DynamicLoadObject runs
 *  inside each helper. */
function IngestRosterIntoGRI(int RosterID)
{
    local ZTGameReplicationInfo DKGRI;

    DKGRI = ZTGameReplicationInfo(WorldInfo.GRI);
    if (DKGRI == None)
    {
        `log("[DK_BULKSYNC] ERROR: IngestRosterIntoGRI(" $ RosterID $ ") -- GRI is not ZTGameReplicationInfo");
        return;
    }

    switch (RosterID)
    {
        case 0:  IngestAllowedWeaponRoster(DKGRI);          break;
        case 1:  IngestTraderWeaponDefRoster(DKGRI);        break;
        case 2:  IngestStartingWeaponRoster(DKGRI);         break;
        case 3:  IngestPerkUpgradeRoster(DKGRI);            break;
        case 4:  IngestSkillUpgradeRoster(DKGRI);           break;
        case 5:  IngestWeaponUpgradeRoster(DKGRI);          break;
        case 6:  IngestEquipmentUpgradeRoster(DKGRI);       break;
        case 7:  IngestSidearmRoster(DKGRI);                break;
        case 8:  IngestGrenadeRoster(DKGRI);                break;
        case 9:  IngestSpecialWaveRoster(DKGRI);            break;
        case 10: IngestZedBuffRoster(DKGRI);                break;
        case 11: IngestSlotCompositionRoster(DKGRI);        break;
    }
}

// Roster 11 ingest: the chunks already wrote every byte into the GRI's paged
// arrays during receive, so there is nothing to decode here. We just log the
// landed state and the count-sum vs the expected slot total. The chunked
// client builder (ZTGameReplicationInfo.GenerateWeaponUpgrades) is gated on
// IsSlotDataComplete() and runs from the SyncTimer flow once this data and the
// upgrade pool are both present -- no need to kick it here (and kicking it
// post-completion would risk a duplicate build pass).
simulated function IngestSlotCompositionRoster(ZTGameReplicationInfo DKGRI)
{
    local int i, sumCnts;

    sumCnts = 0;
    for (i = 0; i < 1024; ++i)
    {
        sumCnts += DKGRI.GetWeaponSlotCnt(i);
    }

    `log("[DK_BULKSYNC] Ingested SlotComposition:" @ BulkRecvReceived[11] @ "chunks, checksum" @ DKGRI.SlotDataChecksum
        @ "sum(counts)=" $ sumCnts @ "expected NumberOfWeaponUpgradeSlots" @ DKGRI.NumberOfWeaponUpgradeSlots);
}

// ===================================================================
// DK_DIAG ? Buy/UWM timing instrumentation (added by DK_DiagWeaponBuyChain.py)
// Server-side BuyWeaponUpgrade timing + Score capture.
// Both-sides UpdateWeaponMagAndCap timing (the suspected hot path).
// Remove with REVERT=1 or by deleting this block.
// ===================================================================

reliable server function BuyWeaponUpgrade(int ItemDefinition, int Cost)
{
    local float TStart;
    local WMPlayerReplicationInfo WMPRI;
    local int ScorePre, ScorePost, LvlPre, LvlPost;

    if (Pawn != None)
        WMPRI = WMPlayerReplicationInfo(Pawn.PlayerReplicationInfo);
    else
        WMPRI = WMPlayerReplicationInfo(PlayerReplicationInfo);

    if (WMPRI != None)
    {
        ScorePre = WMPRI.Score;
        LvlPre = WMPRI.GetWeaponUpgrade(ItemDefinition);
    }
    else
    {
        ScorePre = -1;
        LvlPre = -1;
    }

    TStart = WorldInfo.TimeSeconds;
    `log("[DK_DIAG_BWU] PRE  itemDef=" $ ItemDefinition $ " cost=" $ Cost $ " srvScore=" $ ScorePre $ " srvLvl=" $ LvlPre);

    Super.BuyWeaponUpgrade(ItemDefinition, Cost);

    if (WMPRI != None)
    {
        ScorePost = WMPRI.Score;
        LvlPost = WMPRI.GetWeaponUpgrade(ItemDefinition);
    }
    else
    {
        ScorePost = -1;
        LvlPost = -1;
    }

    `log("[DK_DIAG_BWU] POST itemDef=" $ ItemDefinition $ " srvScore=" $ ScorePost $ " srvLvl=" $ LvlPost $ " durMs=" $ int((WorldInfo.TimeSeconds - TStart) * 1000.0));
}

function UpdateWeaponMagAndCap()
{
    local float TStart;
    local string Side;
    local int InvCount;
    local Inventory Inv;

    TStart = WorldInfo.TimeSeconds;
    Side = (WorldInfo.NetMode == NM_DedicatedServer) ? "SRV" : "CLI";

    InvCount = 0;
    if (Pawn != None && Pawn.InvManager != None)
    {
        for (Inv = Pawn.InvManager.InventoryChain; Inv != None; Inv = Inv.Inventory)
            ++InvCount;
    }
    `log("[DK_DIAG_UWM] PRE  side=" $ Side $ " invCount=" $ InvCount);

    Super.UpdateWeaponMagAndCap();

    `log("[DK_DIAG_UWM] POST side=" $ Side $ " durMs=" $ int((WorldInfo.TimeSeconds - TStart) * 1000.0));
}

// ===================================================================
// SPEEDSTER - Blink Strike activation (default key U, auto-bound via
// ZT_Config_Keybindings -> ActivateSpeedster). Mirrors the dedicated-key
// dispatch used for Hyde: client exec -> reliable server RPC -> the pawn's
// server-authoritative Speedster helper.
// ===================================================================
exec function ActivateSpeedster()
{
    ServerActivateSpeedster();
}

reliable server function ServerActivateSpeedster()
{
    local ZTUpgrade_Perk_Speedster_Helper H;

    if (Pawn == None)
        return;

    foreach Pawn.ChildActors(class'ZTUpgrade_Perk_Speedster_Helper', H)
    {
        H.TryActivate();
        return;
    }
}

// ===================================================================
// PUPPET MASTER SPIKE (throwaway debug). Answers one question: can a player
// possess and DRIVE a zed inside ZU survival (camera + movement + attacks)
// and cleanly return to the human? Spawns a fully player-capable _Versus
// clot (has SM_PlayerZedMove_* + bVersusZed for the 3rd-person cam),
// possesses it, routes fire->zed-moves via bVersusInput, and forces the
// living-player count so a SOLO test does not end the wave.
// Console: PuppetGrab / PuppetDrop.  *** REMOVE BEFORE SHIPPING ***
// ===================================================================
// Client-side helper: route LMB/RMB/V through the native Versus input path so the
// possessed zed performs its OWN special moves (each _Versus zed wires its own).
function PuppetBeginVersusInput()
{
    if (KFPlayerInput(PlayerInput) != None)
        KFPlayerInput(PlayerInput).bVersusInput = true;
}

// ---- PUPPET MASTER SPIKE: transform commands (one per playable _Versus zed) ----
// *** REMOVE BEFORE SHIPPING - replaced by the real perk's zed picker ***
// Trash / medium:
exec function PuppetClot()       { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedClot_Alpha_Versus'); }
exec function PuppetClotKing()   { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedClot_AlphaKing_Versus'); }
exec function PuppetSlasher()    { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedClot_Slasher_Versus'); }
exec function PuppetCrawler()    { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedCrawler_Versus'); }
exec function PuppetBloat()      { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedBloat_Versus'); }
exec function PuppetGorefast()   { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedGorefast_Versus'); }
exec function PuppetStalker()    { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedStalker_Versus'); }
exec function PuppetSiren()      { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedSiren_Versus'); }
exec function PuppetHusk()       { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedHusk_Versus'); }
// Large:
exec function PuppetScrake()     { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedScrake_Versus'); }
exec function PuppetFleshpound() { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'KFGameContent.KFPawn_ZedFleshPound_Versus'); }
// [PUPPET] Case A custom-zed proof: controllable ZR Scrake Emperor. Adds the scrake
// control layer onto the AI-base custom zed (no _Versus parent to inherit from).
// If this possesses/drives/reverts cleanly, the same stamp applies to the rest of the roster.
exec function PuppetScrakeEmperor() { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'ZTPawn_ZedScrake_Emperor_Puppet'); }
// [PUPPET] Generic Case A test hook. Console: `PuppetCustom ZedScrake_Emperor` ->
// ZTPawn_ZedScrake_Emperor_Puppet; `PuppetCustom ZedCrawler_Mini`, etc. Resolves
// any DKPawn_<N>_Puppet by name so the whole Case A roster is testable from one cmd.
exec function PuppetCustom(string N)
{
    local class<KFPawn_Monster> ZedClass;
    ZedClass = class<KFPawn_Monster>(DynamicLoadObject("ZedternalTempered.DKPawn_"$N$"_Puppet", class'Class'));
    if (ZedClass != none)
    {
        PuppetBeginVersusInput();
        ServerPuppetGrabClass(ZedClass);
    }
    else
    {
        `log("[PUPPET] no such custom puppet: DKPawn_"$N$"_Puppet");
    }
}
// Bosses: Patriarch works via ZTPawn_ZedPatriarch_Puppet - a de-bossed
// (IsABoss=false) subclass of the controllable Versus Patriarch - so it spawns,
// is driven, and drops exactly like the trash _Versus zeds above, with no boss
// health bar, music, or wave-boss tracking left to softlock the wave.
exec function PuppetPatriarch()  { PuppetBeginVersusInput(); ServerPuppetGrabClass(class'ZTPawn_ZedPatriarch_Puppet'); }
// Hans stays GATED: the game ships no _Versus (player-controllable) Hans pawn, so
// there is no ability kit to drive - possessing the AI Hans would be movement-only.
// Deferred until/unless a controllable Hans is authored. *** REMOVE WHEN BUILT ***
exec function PuppetHans()       { `log("[PUPPET] Hans has no controllable Versus pawn - boss form unavailable"); }

// Back-compat alias for the original spike command (= alpha clot).
exec function PuppetGrab()
{
    PuppetClot();
}

// --- Doppelganger decoy isolation test.  *** REMOVE BEFORE SHIPPING *** ---
// Spawns one true-likeness decoy just in front of you, using your own pawn/PRI,
// so we can verify appearance + aggro + auto-fire in isolation before the real
// Doppelganger perk (helper / HUD card / keybind) exists.
exec function DecoyTest()
{
    ServerDecoyTest();
}

reliable server function ServerDecoyTest()
{
    local ZTPawn_Doppelganger_Decoy Decoy;
    local KFPawn_Human H;
    local vector SpawnLoc;

    H = KFPawn_Human(Pawn);
    if (H == None)
    {
        `log("[DECOY] no human pawn - aborting");
        return;
    }

    // 200uu of clearance in front of the body, lifted slightly off the floor.
    SpawnLoc = Pawn.Location + (Vector(Pawn.Rotation) * 200.0f);
    SpawnLoc.Z += 20.0f;

    Decoy = Spawn(class'ZTPawn_Doppelganger_Decoy', self, , SpawnLoc, Pawn.Rotation);
    if (Decoy == None)
    {
        `log("[DECOY] spawn FAILED (blocked location? face open space) - reposition and retry");
        return;
    }

    // Test HP so it survives long enough to observe zed aggro.
    Decoy.Health = 500;
    Decoy.HealthMax = 500;

    // 150 dmg per 0.5s tick, 2500uu reach, 12s life, detonate ON (400 dmg / 300uu)
    // so the capstone burst is visible too.
    Decoy.InitDecoy(H, self, 150, 0.5f, 2500.0f, 12.0f, true, 400, 300.0f);
    `log("[DECOY] spawned test decoy");
}

// OverrideHealth > 0 = the Possessor perk's rank/deluxe-scaled puppet health;
// 0 (all spike debug commands) keeps the original flat 5000 test value.
reliable server function ServerPuppetGrabClass(class<KFPawn_Monster> ZedClass, optional int OverrideHealth)
{
    local KFPawn_Monster Z;
    local vector SpawnLoc;

    if (PuppetZed != None)
    {
        `log("[PUPPET] already puppeting - ignoring");
        return;
    }
    if (Pawn == None || KFPawn_Human(Pawn) == None)
    {
        `log("[PUPPET] no human pawn to leave - aborting");
        return;
    }
    if (ZedClass == None)
    {
        `log("[PUPPET] no zed class supplied - aborting");
        return;
    }

    // Spawn the chosen player-capable Versus zed just in front of the human body.
    // 250uu of clearance so the larger zeds (Scrake/FP/boss) have room to fit.
    SpawnLoc = Pawn.Location + (Vector(Pawn.Rotation) * 250.0f);
    SpawnLoc.Z += 30.0f;

    Z = Spawn(ZedClass, , , SpawnLoc);
    if (Z == None)
    {
        `log("[PUPPET] spawn FAILED for " $ string(ZedClass) $ " (blocked location? face open space) - reposition and retry");
        return;
    }

    // Possessor perk passes its rank/deluxe-scaled health; the spike debug
    // commands pass nothing and keep the original flat 5000 test value.
    if (OverrideHealth > 0)
    {
        Z.Health = OverrideHealth;
        Z.HealthMax = OverrideHealth;
    }
    else
    {
        Z.Health = 5000;
        Z.HealthMax = 5000;
    }

    PuppetSavedHuman = KFPawn_Human(Pawn);
    PuppetZed = Z;
    bPuppetRevertPending = false;
    PuppetSavedWeapon = Pawn.Weapon;

    // Keep solo from ending the wave while our controller drives a monster.
    if (KFGameInfo(WorldInfo.Game) != None)
        KFGameInfo(WorldInfo.Game).ForceLivingPlayerCount(1);

    // Park the human body safely so zeds can't kill it while we're away
    // (otherwise the re-possess on revert fails and we genuinely die).
    // bAIZedsIgnoreMe makes CanAITargetThisPawn return false so zeds drop it as
    // a target; the GameInfo also zeroes any in-flight damage to the body.
    PuppetSavedHuman.SetCollision(false, false);
    PuppetSavedHuman.SetHidden(true);
    PuppetSavedHuman.bAIZedsIgnoreMe = true;

    // Release the human (stays alive, controllerless) then take the zed.
    // PossessedBy's human branch sets the character arch/mesh.
    UnPossess();
    Possess(Z, false);

    // Watch for the zed dying -> auto-revert to human instead of game-over.
    SetTimer(0.05f, true, nameof(PuppetWatch));

    // Third-person like Versus: set the zed's view offset + camera mode on the
    // owning client (the camera lives client-side, so this is a client RPC).
    ClientPuppetThirdPerson();

    `log("[PUPPET] grabbed " $ string(ZedClass) $ " zed=" $ Z $ "  parked human=" $ PuppetSavedHuman);
}

exec function PuppetDrop()
{
    // Client-side: restore normal weapon fire routing.
    if (KFPlayerInput(PlayerInput) != None)
        KFPlayerInput(PlayerInput).bVersusInput = false;

    ServerPuppetDrop();
}

reliable server function ServerPuppetDrop()
{
    local KFPawn_Monster Z;

    if (PuppetZed == None || PuppetSavedHuman == None)
    {
        `log("[PUPPET] not puppeting / human lost - nothing to drop");
        return;
    }

    ClearTimer(nameof(PuppetWatch));
    bPuppetRevertPending = false;

    Z = PuppetZed;

    // Restore the parked human body before re-entering it.
    PuppetSavedHuman.SetCollision(true, true);
    PuppetSavedHuman.SetHidden(false);
    PuppetSavedHuman.bAIZedsIgnoreMe = false;

    // Leave the zed, re-enter the human body.
    UnPossess();
    if (PuppetSavedHuman.Health > 0)
        Possess(PuppetSavedHuman, false);
    else
        `log("[PUPPET] saved human is dead - cannot re-possess");

    `log("[PUPPET] post-restore(server): Pawn=" $ string(Pawn) $ " isSaved=" $ string(Pawn == PuppetSavedHuman) $ " ignoreMe=" $ string(PuppetSavedHuman.bAIZedsIgnoreMe) $ " collide=" $ string(PuppetSavedHuman.bCollideActors) $ " block=" $ string(PuppetSavedHuman.bBlockActors) $ " hidden=" $ string(PuppetSavedHuman.bHidden) $ " hp=" $ string(PuppetSavedHuman.Health));

    // Our manual Possess() never ran the client-side pawn handoff that a normal
    // spawn does (input hookup, state, FOV, HUD, and the weapon bring-up). That
    // omission is the real bug: the reverted human ended up with the weapon merely
    // ASSIGNED but dormant and the InvManager half-initialized client-side, so you
    // couldn't fire/switch/throw or even see the weapon despite the pawn looking
    // correct. ClientRestart re-runs the full client setup on the owning client.
    if (PuppetSavedHuman.Health > 0)
        ClientRestart(PuppetSavedHuman);

    // Back to first-person human view (client-side).
    ClientPuppetFirstPerson();

    // Re-equip the weapon the human was holding. PossessedBy does NOT bring a
    // weapon back up, so without this the human is left unable to equip anything.
    // Deferred a tick so the re-possession is fully settled first.
    if (PuppetSavedHuman != None && PuppetSavedHuman.Health > 0)
        SetTimer(0.10f, false, nameof(PuppetRestoreWeapon));

    // Possessor perk: every revert path funnels through here, so this is the
    // single place the helper learns the possession ended (starts the cooldown
    // + flips the HUD card). No-op when the puppet came from the debug commands.
    NotifyPossessorHelperDropped();

    PuppetZed = None;
    PuppetSavedHuman = None;

    // Destroy the throwaway puppet zed - but only if it is still alive (manual
    // PuppetDrop). A zed that DIED is already a corpse mid-death and must not be
    // Destroy()'d here, or we corrupt the engine's in-progress Died() handling.
    if (Z != None && Z.Health > 0)
        Z.Destroy();

    `log("[PUPPET] dropped - back in human");
}

// Fires every 0.05s while puppeting. ReduceDamage caps any lethal hit to
// non-lethal and sets bPuppetRevertPending, so the zed never actually dies;
// this then reverts us to the human, and the player is never counted dead.
function PuppetWatch()
{
    if (PuppetZed == None || PuppetZed.Health <= 0 || bPuppetRevertPending)
        ServerPuppetDrop();
}

// Restore the weapon the human was holding before the transform (server-side).
// PossessedBy does not re-equip on re-possession, leaving the inventory stuck.
function PuppetRestoreWeapon()
{
    local KFInventoryManager KFIM;
    local KFWeapon KFW;

    if (Pawn == None || Pawn.InvManager == None)
    {
        `log("[PUPPET] RestoreWeapon aborted - no pawn/invmanager");
        return;
    }

    KFIM = KFInventoryManager(Pawn.InvManager);
    if (KFIM == None)
        return;

    `log("[PUPPET] RestoreWeapon: saved=" $ string(PuppetSavedWeapon) $ " curWeapon=" $ string(Pawn.Weapon));

    // A server-only equip (ServerSetCurrentWeapon) leaves a remote client WEDGED:
    // the client never runs Weapon.ClientWeaponSet, so its weapon-select bar stays
    // up and it can't fire or switch (ADS still works since it's server-side).
    // Fix: clear the SERVER's stale held/pending weapon so the client-driven equip
    // below won't trip InternalSetCurrentWeapon's "DesiredWeapon == PrevWeapon"
    // abort when its ServerSetCurrentWeapon lands, then have the owning CLIENT run
    // the engine's real switch path (SetCurrentWeapon = client bring-up + server
    // RPC). *** REMOVE BEFORE SHIPPING ***
    KFW = KFWeapon(Pawn.Weapon);
    if (KFW != None)
        KFW.GotoState('Inactive');
    Pawn.Weapon = None;
    KFIM.PendingWeapon = None;

    // Point the saved weapon's server-side refs at the re-possessed human so
    // replication reinforces (rather than re-nulls) the client-side ref repair in
    // ClientPuppetRestoreWeapon. *** REMOVE BEFORE SHIPPING ***
    KFW = KFWeapon(PuppetSavedWeapon);
    if (KFW != None)
    {
        KFW.SetOwner(Pawn);
        KFW.Instigator = Pawn;
        KFW.InvManager = KFIM;
    }

    ClientPuppetRestoreWeapon(PuppetSavedWeapon);

    PuppetSavedWeapon = None;
}

// Owning-client weapon bring-up after revert. A possessed/re-possessed pawn never
// runs the client weapon-set path, so the client stays stuck mid-switch. Run the
// engine's normal switch here: SetCurrentWeapon does the local (client) bring-up
// AND RPCs ServerSetCurrentWeapon so the server brings it up too. Both sides have
// their stale held/pending weapon cleared first so neither aborts.
// *** REMOVE BEFORE SHIPPING ***
reliable client function ClientPuppetRestoreWeapon(Weapon W)
{
    // Server-side is already correct (human re-possessed, Pawn.Weapon = the saved
    // weapon, current). The breakage is purely client-side: the human weapon is
    // bOnlyRelevantToOwner, so during the puppet phase - when the human pawn has no
    // controller and thus no net owner - its client channel is TORN DOWN. On revert
    // it is rebuilt as a BRAND-NEW proxy with InvManager==None (InvManager is not a
    // replicated property), unloaded streamed content, and no ClientGivenTo ever
    // sent to it - so engine Weapon.ClientWeaponSet parks it in PendingClientWeaponSet
    // permanently. That rebuilt proxy also may not have replicated in yet at this
    // instant, so the W ref can be None right now (which is why the old one-shot at a
    // fixed delay fixed nothing). Pawn.Weapon is a replicated property that resolves
    // to the correct proxy, so run a short retry that - once the proxy exists -
    // repairs its dangling refs, kicks the content load once, and re-equips until it
    // escapes PendingClientWeaponSet. *** REMOVE BEFORE SHIPPING ***
    PuppetWeaponRepairTries = 0;
    bPuppetContentKicked = false;
    ClearTimer(nameof(PuppetWeaponRepairTick));
    SetTimer(0.10f, true, nameof(PuppetWeaponRepairTick));
    PuppetWeaponRepairTick();
}

// Client-side repair retry for the rebuilt weapon proxy (see ClientPuppetRestoreWeapon).
// *** REMOVE BEFORE SHIPPING ***
simulated function PuppetWeaponRepairTick()
{
    local KFInventoryManager KFIM;
    local KFWeapon KFW;

    PuppetWeaponRepairTries++;

    if (Pawn == None || Pawn.InvManager == None || PuppetWeaponRepairTries > 40)
    {
        ClearTimer(nameof(PuppetWeaponRepairTick));
        return;
    }

    KFIM = KFInventoryManager(Pawn.InvManager);
    if (KFIM == None)
    {
        ClearTimer(nameof(PuppetWeaponRepairTick));
        return;
    }

    // Wait for the rebuilt weapon proxy to replicate in.
    KFW = KFWeapon(Pawn.Weapon);
    if (KFW == None)
        return;

    // Success: weapon is loaded, switchable, and out of the pending state.
    if (KFW.WeaponContentLoaded && KFW.CanSwitchWeapons() && !KFW.IsInState('PendingClientWeaponSet'))
    {
        ClearTimer(nameof(PuppetWeaponRepairTick));
        return;
    }

    // Repair the refs the rebuilt proxy is missing (InvManager is never replicated;
    // Instigator may lag), then kick the streamed-content load exactly once. With
    // valid refs, the weapon's own 0.03s PendingClientWeaponSet timer (and our
    // explicit ClientWeaponSet) will escape the state, and the weapon activates the
    // moment content finishes loading.
    KFW.SetOwner(Pawn);
    KFW.Instigator = Pawn;
    KFW.InvManager = KFIM;

    if (!bPuppetContentKicked && !KFW.WeaponContentLoaded)
    {
        KFW.ClientGivenTo(Pawn, false);   // triggers StartLoadWeaponContent on the client
        bPuppetContentKicked = true;
    }

    KFW.ClientWeaponSet(false);
}

// Client third-person camera. We DON'T apply it from a one-shot/retry (which
// could fire AFTER the zed died and make the camera follow a corpse - that was
// the recursive client crash). Instead PlayerTick arbitrates it every frame from
// the live pawn state, so it is always correct and self-correcting.
reliable client function ClientPuppetThirdPerson()
{
    bClientPuppetCam = true;
    // Route input through the Versus path on EVERY grab (not just the exec), so the
    // possessed zed's special moves work no matter how the grab was triggered.
    if (KFPlayerInput(PlayerInput) != None)
        KFPlayerInput(PlayerInput).bVersusInput = true;
}

reliable client function ClientPuppetFirstPerson()
{
    bClientPuppetCam = false;
    // Restore normal human input on EVERY revert path. death/wave-end/auto drops all
    // call ServerPuppetDrop -> this RPC, so the exec is no longer the only reset point.
    // A stuck bVersusInput leaves the client in zed-input mode: no fire, no grenade,
    // no weapon switch, empty hands.
    if (KFPlayerInput(PlayerInput) != None)
        KFPlayerInput(PlayerInput).bVersusInput = false;
    SetCameraMode('FirstPerson');
    SetTimer(0.30f, false, nameof(ClientPuppetDiag));
}

// SPIKE diagnostic: log what pawn the OWNING CLIENT actually controls a moment
// after revert, to tell a server-side restore bug from a client/server pawn
// desync (client still stuck on the zed). *** REMOVE BEFORE SHIPPING ***
simulated function ClientPuppetDiag()
{
    local string VInput;
    local string WState;
    local KFWeapon DiagKFW;

    if (KFPlayerInput(PlayerInput) != None)
        VInput = string(KFPlayerInput(PlayerInput).bVersusInput);
    else
        VInput = "no-kfinput";

    if (Pawn == None)
    {
        `log("[PUPPET] client Pawn=None bVersusInput=" $ VInput);
        return;
    }

    DiagKFW = KFWeapon(Pawn.Weapon);
    if (DiagKFW != None)
        WState = " contentLoaded=" $ string(DiagKFW.WeaponContentLoaded) $ " wState=" $ string(DiagKFW.GetStateName()) $ " canSwitch=" $ string(DiagKFW.CanSwitchWeapons());
    else
        WState = " noKFW";

    `log("[PUPPET] client Pawn=" $ string(Pawn) $ " class=" $ string(Pawn.Class) $ " weapon=" $ string(Pawn.Weapon) $ " hidden=" $ string(Pawn.bHidden) $ " hp=" $ string(Pawn.Health) $ " bVersusInput=" $ VInput $ WState);
}

// Per-frame camera arbitration (owning client). Third-person ONLY while driving
// a LIVING zed; a dead zed snaps back to first-person immediately so the camera
// never follows a corpse. The revert is also driven by the reliable
// ClientPuppetFirstPerson RPC; this is the self-correcting safety net.
simulated function UpdatePuppetCamera()
{
    local KFPawn_Monster M;
    local KFThirdPersonCamera TPC;

    if (!bClientPuppetCam || PlayerCamera == None)
        return;

    M = KFPawn_Monster(Pawn);
    if (M == None)
        return; // pawn not (yet) the zed, or reverted - leave the camera alone

    if (M.Health > 0)
    {
        if (PlayerCamera.CameraStyle != 'ThirdPerson' && KFPlayerCamera(PlayerCamera) != None)
        {
            TPC = KFThirdPersonCamera(KFPlayerCamera(PlayerCamera).ThirdPersonCam);
            if (TPC != None)
                TPC.SetViewOffset(M.ThirdPersonViewOffset);
            SetCameraMode('ThirdPerson');
        }
    }
    else if (PlayerCamera.CameraStyle == 'ThirdPerson')
    {
        // Zed died - stop following it instantly (crash-safe).
        SetCameraMode('FirstPerson');
    }
}

event PlayerTick(float DeltaTime)
{
    super.PlayerTick(DeltaTime);
    UpdatePuppetCamera();
}

// ===================================================================
// PUPPET MASTER SPIKE - melee/attack wiring (throwaway debug).
// Survival's StartFire routes to WEAPON fire; a possessed zed has no
// weapon, so the claws never swung ("didn't see its claws"). While
// puppeting, route fire input to the zed's player special moves instead.
// Reads the move handles that every _Versus zed defines
// (SM_PlayerZedMove_LMB/_RMB/_V -> that zed's KFSM_Player*_Melee/Grab/Rally),
// so this works for ANY eligible Versus zed, not just the Alpha clot.
// We are in state PlayerWalking while driving, so this global override is
// the one that fires. *** REMOVE BEFORE SHIPPING ***
// ===================================================================
exec function StartFire(optional byte FireModeNum)
{
    if (PuppetZed != None && PuppetZed.IsAliveAndWell())
    {
        if (FireModeNum == 0)
            PuppetZed.StartPlayerZedMove(SM_PlayerZedMove_LMB);   // claws
        else if (FireModeNum == 1)
            PuppetZed.StartPlayerZedMove(SM_PlayerZedMove_RMB);   // grab
        return;
    }

    super.StartFire(FireModeNum);
}

exec function StopFire(optional byte FireModeNum)
{
    if (PuppetZed != None)
    {
        if (FireModeNum == 0)
            PuppetZed.StopPlayerZedMove(SM_PlayerZedMove_LMB);
        else if (FireModeNum == 1)
            PuppetZed.StopPlayerZedMove(SM_PlayerZedMove_RMB);
        return;
    }

    super.StopFire(FireModeNum);
}

// V/rally for the test. Bind with:  setbind V PuppetRally
exec function PuppetRally()
{
    if (PuppetZed != None && PuppetZed.IsAliveAndWell())
        PuppetZed.StartPlayerZedMove(SM_PlayerZedMove_V);
}

// ---- Patriarch-only extra attacks (bound J/K/P by ZT_Config_Keybindings) ----
// Every playable Versus zed wires only LMB/RMB/V; the Patriarch also defines
// three more player moves (mortar, missile, heal) that nothing routed to until
// now. Each StartPlayerZedMove is a harmless no-op on any form whose special-
// move table has no class for that handle, so these are safe to leave bound.

// Mortar barrage (SM_PlayerZedMove_G). Targeting is retargeted at zeds in
// ZTPawn_ZedPatriarch_Puppet.CollectMortarTargets (vanilla hunts humans).
exec function PuppetMortar()
{
    if (PuppetZed != None && PuppetZed.IsAliveAndWell())
        PuppetZed.StartPlayerZedMove(SM_PlayerZedMove_G);
}

// Missile barrage (SM_PlayerZedMove_MMB) - camera-trace aimed, already hits
// whatever you are looking at, so no targeting override needed.
exec function PuppetMissile()
{
    if (PuppetZed != None && PuppetZed.IsAliveAndWell())
        PuppetZed.StartPlayerZedMove(SM_PlayerZedMove_MMB);
}

// Self-heal (SM_PlayerZedMove_Q) - vanilla rules apply (needs < 50% health
// and one of the Patriarch's 3 heal charges).
exec function PuppetHeal()
{
    if (PuppetZed != None && PuppetZed.IsAliveAndWell())
        PuppetZed.StartPlayerZedMove(SM_PlayerZedMove_Q);
}

defaultproperties
{
    PerkList(0)=(PerkClass=class'ZedternalTempered.ZTPerk')
    CheatClass=class'ZedternalTempered.ZTCheatManager'
    
    bRoguelikeSelectionActive=false
    
    BulkRecvAllDone=false
    BulkSendAllDone=false
    
    Name="Default__ZTPlayerController"
}
