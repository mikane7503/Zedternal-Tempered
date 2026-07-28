/**
 * DKCheatManager
 * Extended cheat manager for Zedternal Unlimited development tools.
 *
 * Console commands:
 *   StatOverlay          - (Moved to DKPlayerController — works without cheats enabled)
 *   UnlockAllReforged    - Unlock all 131 Reforged weapons in trader (sets all bitmask bits)
 *   LockAllReforged      - Lock all Reforged weapons (clears all bitmask bits)
 *   ReforgedStatus       - Show Reforged weapon registration and unlock status
 *   DumpTraderItems      - List all items in TraderItems.SaleItems with ClassName info
 *   ForceEvent <name>    - Force a specific event wave next wave (e.g. ForceEvent RAGE)
 *   StopEvent            - Stop the current event wave immediately
 *   EventList            - List all event wave names and IDs
 */
class DKCheatManager extends WMCheatManager;

// ===================================================================
// STAT OVERLAY — handled by DKPlayerController.StatOverlay()
// ===================================================================

// ===================================================================
// REFORGED WEAPON DEBUG COMMANDS
// ===================================================================

/** Unlock all 131 Reforged weapons — sets every bitmask bit so all appear in trader */
exec function UnlockAllReforged()
{
    local DKGameReplicationInfo DKGRI;
    local DKPlayerReplicationInfo DKPRI;
    local int TotalReforged, i, UnlockedCount;

    DKGRI = DKGameReplicationInfo(WorldInfo.GRI);
    DKPRI = DKPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKGRI == None || DKPRI == None)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] ERROR: Missing DKGameReplicationInfo or DKPlayerReplicationInfo!");
        return;
    }

    if (DKGRI.ReforgedStartIndex <= 0)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] ERROR: No Reforged weapons registered (ReforgedStartIndex=" $ DKGRI.ReforgedStartIndex $ ")");
        return;
    }

    TotalReforged = DKGRI.AllowedWeaponsList.Length - DKGRI.ReforgedStartIndex;
    UnlockedCount = 0;

    // Per-player unlock (was GRI-shared; now lives on the local player's PRI).
    for (i = 0; i < TotalReforged; ++i)
    {
        if (DKPRI.UnlockReforgedWeapon(i))
            ++UnlockedCount;
    }

    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] Unlocked" @ UnlockedCount @ "Reforged weapons (" $ TotalReforged @ "total). Open trader to see them.");
    `log("[DK_DEV] UnlockAllReforged: Unlocked" @ UnlockedCount @ "new," @ TotalReforged @ "total Reforged weapons");
}

/** Lock all Reforged weapons — clears all bitmask bits */
exec function LockAllReforged()
{
    local DKPlayerReplicationInfo DKPRI;

    DKPRI = DKPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKPRI == None)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] ERROR: PRI is not DKPlayerReplicationInfo!");
        return;
    }

    DKPRI.ReforgeFlags_0 = 0;
    DKPRI.ReforgeFlags_1 = 0;
    DKPRI.ReforgeFlags_2 = 0;
    DKPRI.ReforgeFlags_3 = 0;
    DKPRI.ReforgeFlags_4 = 0;
    DKPRI.bForceNetUpdate = True;

    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] All Reforged weapons LOCKED. Bitmask cleared.");
    `log("[DK_DEV] LockAllReforged: All bitmask flags cleared");
}

/** Show Reforged weapon registration status and unlock counts */
exec function ReforgedStatus()
{
    local DKGameReplicationInfo DKGRI;
    local DKPlayerReplicationInfo DKPRI;
    local int TotalReforged, UnlockedCount;
    local string Info;

    DKGRI = DKGameReplicationInfo(WorldInfo.GRI);
    DKPRI = DKPlayerReplicationInfo(PlayerReplicationInfo);
    if (DKGRI == None || DKPRI == None)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] ERROR: Missing DKGameReplicationInfo or DKPlayerReplicationInfo!");
        return;
    }

    TotalReforged = DKGRI.AllowedWeaponsList.Length - DKGRI.ReforgedStartIndex;
    UnlockedCount = DKGRI.GetTotalReforgedUnlocked();

    Info = "[DK_DEV] === REFORGED STATUS (this player) ===";
    Info = Info $ "\nReforgedStartIndex:" @ DKGRI.ReforgedStartIndex;
    Info = Info $ "\nAllowedWeaponsList.Length:" @ DKGRI.AllowedWeaponsList.Length;
    Info = Info $ "\nTotal Reforged weapons:" @ TotalReforged;
    Info = Info $ "\nUnlocked:" @ UnlockedCount @ "/" $ TotalReforged;
    Info = Info $ "\nBitmask values: [" $ DKPRI.ReforgeFlags_0 $ "," @ DKPRI.ReforgeFlags_1 $ "," @ DKPRI.ReforgeFlags_2 $ "," @ DKPRI.ReforgeFlags_3 $ "," @ DKPRI.ReforgeFlags_4 $ "]";

    if (DKGRI.TraderItems != None)
        Info = Info $ "\nTraderItems.SaleItems.Length:" @ DKGRI.TraderItems.SaleItems.Length;
    else
        Info = Info $ "\nTraderItems: None!";

    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText(Info);
    `log(Info);
}

/** Dump all trader items to console and log — shows ClassName to verify SetItemsInfo worked */
exec function DumpTraderItems()
{
    local WMGameReplicationInfo WMGRI;
    local int i;
    local string Line;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None || WMGRI.TraderItems == None)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] ERROR: No GRI or TraderItems!");
        return;
    }

    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] === TRADER ITEMS (" $ WMGRI.TraderItems.SaleItems.Length @ "total) ===");
    `log("[DK_DEV] === TRADER ITEMS (" $ WMGRI.TraderItems.SaleItems.Length @ "total) ===");

    for (i = 0; i < WMGRI.TraderItems.SaleItems.Length; ++i)
    {
        Line = "[" $ i $ "]";
        Line = Line @ "WeaponDef=" $ PathName(WMGRI.TraderItems.SaleItems[i].WeaponDef);
        Line = Line @ "ClassName=" $ WMGRI.TraderItems.SaleItems[i].ClassName;
        Line = Line @ "ItemID=" $ WMGRI.TraderItems.SaleItems[i].ItemID;

        // Only log Reforged weapons to console (too many items otherwise)
        if (InStr(string(WMGRI.TraderItems.SaleItems[i].ClassName), "Reforged") != INDEX_NONE
            || InStr(PathName(WMGRI.TraderItems.SaleItems[i].WeaponDef), "Reforged") != INDEX_NONE)
        {
            LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText(Line);
        }

        // Log ALL items to launch.log for thorough debugging
        `log(Line);
    }

    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] Full list written to launch.log. Reforged items shown above.");
}

// ===================================================================
// EVENT WAVE DEBUG COMMANDS
// ===================================================================

/** Force a specific event wave on the next wave start. Use EventList to see IDs. */
exec function ForceEvent(string EventName)
{
    local DKGameInfo_Endless DKGI;
    local byte EventID;

    DKGI = DKGameInfo_Endless(WorldInfo.Game);
    if (DKGI == None)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] ERROR: Not a DK Endless game!");
        return;
    }

    EventID = class'DKConfig_EventWave'.static.GetEventIDFromName(EventName);
    if (EventID == 0)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] Unknown event: " $ EventName $ ". Use EventList to see valid names.");
        return;
    }

    DKGI.ForcedEventWaveID = EventID;
    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] Event '" $ class'DKConfig_EventWave'.static.GetEventName(EventID) $ "' (ID " $ EventID $ ") will trigger next wave.");
    `log("[DK_DEV] ForceEvent: Queued event" @ EventID @ class'DKConfig_EventWave'.static.GetEventName(EventID));
}

/** Stop the current event wave immediately */
exec function StopEvent()
{
    local DKGameReplicationInfo DKGRI;
    local DKGameInfo_Endless DKGI;

    DKGRI = DKGameReplicationInfo(WorldInfo.GRI);
    DKGI = DKGameInfo_Endless(WorldInfo.Game);

    if (DKGRI == None)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] ERROR: No DKGameReplicationInfo!");
        return;
    }

    if (DKGRI.ActiveEventWaveID == 0)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] No event wave is currently active.");
        return;
    }

    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] Stopping event: " $ class'DKConfig_EventWave'.static.GetEventName(DKGRI.ActiveEventWaveID));

    if (DKGI != None && DKGI.EventWaveManager != None)
        DKGI.EventWaveManager.EndEvent();

    DKGRI.ActiveEventWaveID = 0;
}

/** List all available event wave names and IDs */
exec function EventList()
{
    local byte i;
    local string EvtName;

    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] === EVENT WAVES ===");
    for (i = 7; i <= 22; ++i)
    {
        EvtName = class'DKConfig_EventWave'.static.GetEventName(i);
        if (EvtName != "None")
            LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("  ID" @ i @ "-" @ EvtName);
    }
    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("Usage: ForceEvent <name> (e.g. ForceEvent RAGE)");
}

// ===================================================================
// WEAPON UPGRADE DEBUG
// ===================================================================

/** Debug why Reforged weapon upgrades don't show in UPG menu */
exec function DebugWeaponUpgrades()
{
    local KFWeapon W;
    local WMGameReplicationInfo WMGRI;
    local int i, MatchCount;

    WMGRI = WMGameReplicationInfo(WorldInfo.GRI);
    if (WMGRI == None)
    {
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("[DK_DEV] No WMGRI");
        return;
    }

    // Log all weapons in inventory
    foreach Pawn.InvManager.InventoryActors(class'KFWeapon', W)
    {
        `log("DK DEBUG: Inventory weapon:" @ W.Class @ "| PathName=" @ PathName(W.Class));
        LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("Inv:" @ W.Class);
    }

    // Check upgrade slots for Reforged entries
    MatchCount = 0;
    `log("DK DEBUG: WeaponUpgradeSlotsList.Length =" @ WMGRI.WeaponUpgradeSlotsList.Length);
    for (i = 0; i < WMGRI.WeaponUpgradeSlotsList.Length; ++i)
    {
        if (WMGRI.WeaponUpgradeSlotsList[i].KFWeapon != None
            && InStr(string(WMGRI.WeaponUpgradeSlotsList[i].KFWeapon), "Reforged") != INDEX_NONE)
        {
            if (MatchCount < 5)
            {
                `log("DK DEBUG: Reforged slot" @ i @ "KFWeapon =" @ WMGRI.WeaponUpgradeSlotsList[i].KFWeapon
                    @ "| Upgrade =" @ WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade);
                LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("Slot" @ i @ "=" @ WMGRI.WeaponUpgradeSlotsList[i].KFWeapon);
            }
            ++MatchCount;
        }
    }
    `log("DK DEBUG: Total Reforged upgrade slots found:" @ MatchCount);
    LocalPlayer(Player).ViewportClient.ViewportConsole.OutputText("Total Reforged upgrade slots:" @ MatchCount);

    // Now test the actual IsWeaponInInventory match logic
    foreach Pawn.InvManager.InventoryActors(class'KFWeapon', W)
    {
        if (InStr(string(W.Class), "Reforged") != INDEX_NONE)
        {
            for (i = 0; i < WMGRI.WeaponUpgradeSlotsList.Length; ++i)
            {
                if (WMGRI.WeaponUpgradeSlotsList[i].KFWeapon != None
                    && InStr(string(WMGRI.WeaponUpgradeSlotsList[i].KFWeapon), "Reforged") != INDEX_NONE)
                {
                    `log("DK DEBUG: Match test: inv=" @ W.Class @ "vs slot=" @ WMGRI.WeaponUpgradeSlotsList[i].KFWeapon
                        @ "| ChildOf(inv,slot)=" @ ClassIsChildOf(W.Class, WMGRI.WeaponUpgradeSlotsList[i].KFWeapon)
                        @ "| ChildOf(slot,inv)=" @ ClassIsChildOf(WMGRI.WeaponUpgradeSlotsList[i].KFWeapon, W.Class));
                    break; // Just test first match
                }
            }
        }
    }
}

defaultproperties
{
    // DK custom zeds
    ZedTypes.Add((SearchName="Broodmother",ZedClass=class'ZedternalRBPerkpackage.DKPawn_ZedCrawler_Broodmother'))

    Name="Default__DKCheatManager"
}
