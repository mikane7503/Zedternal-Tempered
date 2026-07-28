// ===================================================================
// DKMessageManager - prioritized message router with localization
// ===================================================================
// LEGACY API (English-only):
//   SendCritical / SendImportant / SendMinor / SendGameMessage
//   - Take a pre-formatted string. Server formats, sends to client.
//   - All clients see whatever language the server formatted in.
//
// LOCALIZED API (preferred for new code):
//   SendCriticalLoc / SendImportantLoc / SendMinorLoc / SendLocalizedMessage
//   - Take a name key + up to 2 string args.
//   - Wire format sends (key, arg1, arg2) — client looks up its own
//     locale and renders. Each client sees its own language.
//   - Localization keys live in [DKMessages] in the .int / .kor / etc.
//   - Hardcoded English fallbacks in GetEnglishFallback() handle the
//     case where the .int is missing entirely.
// ===================================================================
class DKMessageManager extends Object
    config(ZedternalRBPerkpackage);

// Message priority levels for filtering
enum EMessagePriority
{
    MP_Hidden,      // Don't show at all
    MP_Minor,       // Progress updates, stack counts (white/gray)
    MP_Important,   // Skill activations, buff gains/losses (gold/yellow)
    MP_Critical     // Major events: transformations, achievements (red/orange)
};

// Configuration variables - can be set in config file
var config bool bShowMinor;
var config bool bShowImportant;
var config bool bShowCritical;

// ===================================================================
// LEGACY API (unchanged - kept for back-compat with non-localized callers)
// ===================================================================

// Static function to send prioritized messages to HUD notification feed
// FIXED: Now uses replication helper to properly communicate server -> client
static function SendGameMessage(
    KFPlayerController KFPC, 
    string Message, 
    optional EMessagePriority Priority = MP_Important
)
{
    local DKMessageReplicator Replicator;
    local DKHudWrapper CustomHUD;
    local Color MessageColor;
    
    if (KFPC == None)
        return;
    
    // Check if this priority level should be displayed
    if (!ShouldShowPriority(Priority))
        return;
    
    // Get the color for this priority level
    MessageColor = GetColorForPriority(Priority);
    
    // CRITICAL FIX: Check if we're on the server or client
    if (KFPC.Role == ROLE_Authority && KFPC.RemoteRole != ROLE_None)
    {
        // We're on the SERVER - use replicator to send to client
        Replicator = class'DKMessageReplicator'.static.GetReplicatorForPlayer(KFPC);
        if (Replicator != None)
        {
            Replicator.SendNotificationToClient(Message, MessageColor, Priority);
        }
        else
        {
            // Fallback if replicator fails
            KFPC.ClientMessage(Message, 'Event');
        }
    }
    else
    {
        // We're on the CLIENT or in single-player - access HUD directly
        CustomHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
        if (CustomHUD != None)
        {
            CustomHUD.AddNotificationMessage(Message, MessageColor, Priority);
        }
        else
        {
            // Fallback to regular chat if custom HUD not available
            KFPC.ClientMessage(Message, 'Event');
        }
    }
}

// Check if a message priority should be displayed
static function bool ShouldShowPriority(EMessagePriority Priority)
{
    switch(Priority)
    {
        case MP_Hidden:
            return false;
            
        case MP_Minor:
            // If config hasn't been set (all false), default to showing
            // Otherwise respect the config setting
            if (!default.bShowMinor && !default.bShowImportant && !default.bShowCritical)
                return true; // First time / no config - show all
            return default.bShowMinor;
            
        case MP_Important:
            if (!default.bShowMinor && !default.bShowImportant && !default.bShowCritical)
                return true; // First time / no config - show all
            return default.bShowImportant;
            
        case MP_Critical:
            if (!default.bShowMinor && !default.bShowImportant && !default.bShowCritical)
                return true; // First time / no config - show all
            return default.bShowCritical;
    }
    
    return true; // Default to showing if priority is unknown
}

// Get color based on priority level
static function Color GetColorForPriority(EMessagePriority Priority)
{
    local Color ResultColor;
    
    switch(Priority)
    {
        case MP_Critical:
            // Bright red/orange for critical messages
            ResultColor.R = 255;
            ResultColor.G = 80;
            ResultColor.B = 40;
            ResultColor.A = 255;
            break;
            
        case MP_Important:
            // Gold/yellow for important messages
            ResultColor.R = 255;
            ResultColor.G = 215;
            ResultColor.B = 0;
            ResultColor.A = 255;
            break;
            
        case MP_Minor:
            // Light gray/white for minor messages
            ResultColor.R = 200;
            ResultColor.G = 200;
            ResultColor.B = 200;
            ResultColor.A = 255;
            break;
            
        case MP_Hidden:
        default:
            // Fallback white
            ResultColor.R = 255;
            ResultColor.G = 255;
            ResultColor.B = 255;
            ResultColor.A = 255;
            break;
    }
    
    return ResultColor;
}

// Utility function for quick critical messages
static function SendCritical(KFPlayerController KFPC, string Message)
{
    SendGameMessage(KFPC, Message, MP_Critical);
}

// Utility function for quick important messages
static function SendImportant(KFPlayerController KFPC, string Message)
{
    SendGameMessage(KFPC, Message, MP_Important);
}

// Utility function for quick minor messages
static function SendMinor(KFPlayerController KFPC, string Message)
{
    SendGameMessage(KFPC, Message, MP_Minor);
}

// ===================================================================
// LOCALIZED API
// ===================================================================
// Server-side calls send (key, args) over the wire; the client localizes
// using its own active locale's .int / .kor / .deu / etc. This means a
// Korean client always sees Korean even when the server is in English.
//
// Lookup chain on the client:
//   1. Active locale's ZedternalRBPerkpackage.<lang> [DKMessages] KEY=...
//   2. ZedternalRBPerkpackage.int [DKMessages] KEY=... (English fallback)
//   3. GetEnglishFallback(KEY) — hardcoded English in this file
//   4. string(KEY) — last-resort key name (only if KEY is missing from
//      both the .int AND the GetEnglishFallback() lookup table)
// ===================================================================

// Localize a message key with up to 2 placeholder substitutions (%1, %2).
// Reverse order Repl so a "%1" embedded in Arg2 is not re-replaced.
static function string LocalizeMessage(
    name MessageKey, 
    optional string Arg1, 
    optional string Arg2
)
{
    local string Template;
    
    Template = class'DKLocalizationHelper'.static.TryLocalize(
        "ZedternalRBPerkpackage",
        "DKMessages",
        string(MessageKey),
        GetEnglishFallback(MessageKey)
    );
    
    // Replace %2 first (so any "%1" inside Arg2's literal doesn't get expanded)
    if (Arg2 != "")
        Template = Repl(Template, "%2", Arg2);
    if (Arg1 != "")
        Template = Repl(Template, "%1", Arg1);
    
    return Template;
}

// Centralized lookup for English fallbacks. Used as the last layer of
// graceful degradation if the .int file is missing or corrupted.
// Keep entries here in sync with the [DKMessages] section in
// ZedternalRBPerkpackage.int.
static function string GetEnglishFallback(name MessageKey)
{
    switch (MessageKey)
    {
        // Ability slot system
        case 'AbilitySlotEmpty':       return "Ability Slot %1 is empty!";
        case 'UnknownAbilityType':     return "Unknown ability type in slot %1!";
        case 'AllAbilitySlotsFull':    return "All ability slots full! Type 'ReplaceAbilitySlot <1-4>' to replace a slot.";
        case 'AbilityAdded':           return "Ability '%1' added to Slot %2!";
        case 'InvalidSlot':            return "Invalid slot! Use 1-4.";
        case 'SlotAlreadyEmpty':       return "Slot %1 is already empty!";
        case 'SlotCleared':            return "Slot %1 cleared. Purchase a new ability skill to fill it.";
        case 'ActiveAbilitiesHeader':  return "=== ACTIVE ABILITIES ===";
        case 'SlotStatusFilled':       return "Slot %1: %2";
        case 'SlotStatusEmpty':        return "Slot %1: [EMPTY]";

        // Predator trophy system
        case 'PredatorNotActive':      return "DropTrophy: Predator perk not active";
        case 'TrophiesInventory':      return "Trophies (%1): %2";
        case 'DiscardedAllTrophies':   return "Discarded all %1 trophies";
        case 'DroppedTrophy':          return "Dropped %1 trophy";
        case 'NoTrophyToDrop':         return "No %1 trophy to drop";

        // Rank-up announcements
        case 'RankUpSelf':             return "You reached %1!";
        case 'RankUpOther':            return "%1 reached %2!";

        // ZURank debug command
        case 'ZURankHeader':           return "=== ZU RANK DEBUG ===";
        case 'ZURankStoredXP':         return "Stored XP: %1";
        case 'ZURankRank':             return "Rank: %1 (%2)";
        case 'ZURankCachedClientRank': return "CachedClientRank: %1";
        case 'ZURankPendingXP':        return "PendingRankXP: %1";
        case 'ZURankPRIRank':          return "PRI.PlayerRank: %1";
        case 'ZURankPRIError':         return "PRI: None or not DKPlayerReplicationInfo!";
        case 'ZURankNextAt':           return "Next rank at: %1 XP";

        // ZUSetXP
        case 'ZUSetXPDone':            return "Set rank XP to %1";

        // Rank toggle commands
        case 'RankMessagesOn':         return "Rank-up messages: ON";
        case 'RankMessagesOff':        return "Rank-up messages: OFF";
        case 'RankHUDOn':              return "Rank HUD: ON";
        case 'RankHUDOff':             return "Rank HUD: OFF";

        // DKMusicVolume
        case 'MusicVolumeCurrent':     return "Event music volume: %1%";
        case 'MusicVolumeUsage':       return "Usage: DKMusicVolume 0.0-1.0 (0=mute, 1=max)";
        case 'MusicVolumeSet':         return "Event music volume set to %1%";

        // ZUEvent listing (event names stay literal — they are command keywords)
        case 'ZUEventHeader':          return "=== ZU EVENT WAVE ===";
        case 'ZUEventSensoryList':     return "Sensory: Isolation, Blackout, DeadSilence, Paranoia, Redacted, Fog";
        case 'ZUEventGameplayList1':   return "Gameplay: VIP, HotPotato, Highlander, RAGE, Amogus, Chain, OITC, Marked";
        case 'ZUEventGameplayList2':   return "Gameplay: Nemesis, Duel";
        case 'ZUEventUsage':           return "Usage: ZUEvent <name> to force next wave";

        // ServerForceEventWave responses (sent via ClientLocalizedChat RPC)
        case 'EventWaveCleared':       return "Event Wave: Cleared forced event.";
        case 'EventWaveUnknown':       return "Event Wave: Unknown event '%1'. Use ZUEvent with no args to see the list.";
        case 'EventWaveSet':           return "Event Wave: '%1' will trigger on next wave start.";

        // Detonator perk window
        case 'DetonatorWindowStarted': return "DETONATOR ACTIVE - Kills detonate for %1s!";
        case 'DetonatorWindowExpired': return "DETONATOR window expired";

        // Gambit static popups (no dynamic args)
        case 'GambitWildCard':              return "WILD CARD! Gambit auto-completed!";
        case 'GambitRoyalFlush':            return ">>> ROYAL FLUSH! <<< Rewards TRIPLED!";
        case 'GambitDoubleOrNothingWin':    return "DOUBLE OR NOTHING: WIN! Rewards doubled!";
        case 'GambitDoubleOrNothingBust':   return "DOUBLE OR NOTHING: BUST! Rewards lost!";
        case 'GambitBluff':                 return "BLUFF! Gambit sacrificed to cheat death!";
    }
    return string(MessageKey);
}

// Send a localized prioritized message. Server-side this routes to the
// client via DKMessageReplicator (sending key+args, NOT the formatted
// string). Client-side this localizes locally and renders to HUD.
static function SendLocalizedMessage(
    KFPlayerController KFPC,
    name MessageKey,
    optional string Arg1,
    optional string Arg2,
    optional EMessagePriority Priority = MP_Important
)
{
    local DKMessageReplicator Replicator;
    local DKHudWrapper CustomHUD;
    local Color MessageColor;
    local string LocalMessage;
    
    if (KFPC == None)
        return;
    
    if (!ShouldShowPriority(Priority))
        return;
    
    MessageColor = GetColorForPriority(Priority);
    
    if (KFPC.Role == ROLE_Authority && KFPC.RemoteRole != ROLE_None)
    {
        // SERVER -> CLIENT: send key+args, let client localize
        Replicator = class'DKMessageReplicator'.static.GetReplicatorForPlayer(KFPC);
        if (Replicator != None)
        {
            Replicator.SendLocalizedNotificationToClient(
                MessageKey, Arg1, Arg2, MessageColor, Priority
            );
        }
        else
        {
            // Replicator unavailable — localize on server using server's
            // locale and fall back to ClientMessage. Imperfect but rare.
            LocalMessage = LocalizeMessage(MessageKey, Arg1, Arg2);
            KFPC.ClientMessage(LocalMessage, 'Event');
        }
    }
    else
    {
        // CLIENT or solo: localize locally and add to HUD
        LocalMessage = LocalizeMessage(MessageKey, Arg1, Arg2);
        CustomHUD = class'DKHudWrapper'.static.GetReaperHUD(KFPC);
        if (CustomHUD != None)
        {
            CustomHUD.AddNotificationMessage(LocalMessage, MessageColor, Priority);
        }
        else
        {
            KFPC.ClientMessage(LocalMessage, 'Event');
        }
    }
}

// Convenience wrappers per priority level
static function SendMinorLoc(
    KFPlayerController KFPC, 
    name MessageKey, 
    optional string Arg1, 
    optional string Arg2
)
{
    SendLocalizedMessage(KFPC, MessageKey, Arg1, Arg2, MP_Minor);
}

static function SendImportantLoc(
    KFPlayerController KFPC, 
    name MessageKey, 
    optional string Arg1, 
    optional string Arg2
)
{
    SendLocalizedMessage(KFPC, MessageKey, Arg1, Arg2, MP_Important);
}

static function SendCriticalLoc(
    KFPlayerController KFPC, 
    name MessageKey, 
    optional string Arg1, 
    optional string Arg2
)
{
    SendLocalizedMessage(KFPC, MessageKey, Arg1, Arg2, MP_Critical);
}

defaultproperties
{
    Name="Default__DKMessageManager"
}
