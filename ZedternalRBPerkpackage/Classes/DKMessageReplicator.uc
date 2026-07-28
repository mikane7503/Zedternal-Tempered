// Lightweight replication helper that bridges server -> client for HUD notifications
// One instance spawned per player to handle message replication
class DKMessageReplicator extends ReplicationInfo;

var KFPlayerController OwningPC;

replication
{
    if (bNetDirty)
        OwningPC;
}

// LEGACY: Server sends a pre-formatted string (one language for all clients).
// Kept for back-compat with any non-localized callers.
reliable client function SendNotificationToClient(string Message, Color MessageColor, byte Priority)
{
    local DKHudWrapper CustomHUD;
    
    // This executes on the CLIENT where HUD exists
    if (OwningPC != None)
    {
        CustomHUD = class'DKHudWrapper'.static.GetReaperHUD(OwningPC);
        if (CustomHUD != None)
        {
            CustomHUD.AddNotificationMessage(Message, MessageColor, Priority);
        }
    }
}

// LOCALIZED: Server sends key+args, client looks up its own locale and
// formats. Each client sees its native language regardless of where the
// server is hosted or what language the server admin uses.
reliable client function SendLocalizedNotificationToClient(
    name MessageKey, 
    string Arg1, 
    string Arg2, 
    Color MessageColor, 
    byte Priority
)
{
    local DKHudWrapper CustomHUD;
    local string Message;
    
    if (OwningPC == None)
        return;
    
    // Localize on the CLIENT using its active locale
    Message = class'DKMessageManager'.static.LocalizeMessage(MessageKey, Arg1, Arg2);
    
    CustomHUD = class'DKHudWrapper'.static.GetReaperHUD(OwningPC);
    if (CustomHUD != None)
    {
        CustomHUD.AddNotificationMessage(Message, MessageColor, Priority);
    }
    else
    {
        // Fallback to chat if HUD unavailable
        OwningPC.ClientMessage(Message, 'Event');
    }
}

// Called from server - shows perk unlock popup on client (with texture)
reliable client function ShowPerkUnlockPopup(string PerkName, Texture2D PerkIcon)
{
    local DKHudWrapper CustomHUD;
    
    // This executes on the CLIENT where HUD exists
    if (OwningPC != None)
    {
        CustomHUD = class'DKHudWrapper'.static.GetReaperHUD(OwningPC);
        if (CustomHUD != None)
        {
            CustomHUD.ShowPerkUnlockNotification(PerkName, PerkIcon);
            `log("DKMessageReplicator (CLIENT): Showed perk unlock popup for" @ PerkName);
        }
        else
        {
            `log("DKMessageReplicator (CLIENT): ERROR - Could not get HUD for unlock popup");
        }
    }
}

// NEW: Called from server - shows perk unlock popup by getting icon client-side
reliable client function ShowPerkUnlockPopupByIndex(string PerkName, int PerkIndex)
{
    local DKHudWrapper CustomHUD;
    local WMGameReplicationInfo WMGRI;
    local Texture2D PerkIcon;
    
    // This executes on the CLIENT where HUD exists and we can call simulated functions
    if (OwningPC == None) return;
    
    // Get the icon client-side where we CAN access default arrays
    WMGRI = WMGameReplicationInfo(OwningPC.WorldInfo.GRI);
    if (WMGRI != None && PerkIndex != INDEX_NONE && PerkIndex < WMGRI.PerkUpgradesList.Length)
    {
        PerkIcon = WMGRI.PerkUpgradesList[PerkIndex].PerkUpgrade.static.GetUpgradeIcon(0);
    }
    
    CustomHUD = class'DKHudWrapper'.static.GetReaperHUD(OwningPC);
    if (CustomHUD != None)
    {
        CustomHUD.ShowPerkUnlockNotification(PerkName, PerkIcon);
        `log("DKMessageReplicator (CLIENT): Showed perk unlock popup for" @ PerkName @ "using index" @ PerkIndex);
    }
    else
    {
        `log("DKMessageReplicator (CLIENT): ERROR - Could not get HUD for unlock popup");
    }
}

// Find or create replicator for a player
static function DKMessageReplicator GetReplicatorForPlayer(KFPlayerController KFPC)
{
    local DKMessageReplicator Replicator;
    
    if (KFPC == None)
        return None;
    
    // Try to find existing replicator
    foreach KFPC.DynamicActors(class'DKMessageReplicator', Replicator)
    {
        if (Replicator.OwningPC == KFPC)
            return Replicator;
    }
    
    // Create new one if not found
    Replicator = KFPC.Spawn(class'DKMessageReplicator', KFPC);
    if (Replicator != None)
    {
        Replicator.OwningPC = KFPC;
    }
    
    return Replicator;
}

defaultproperties
{
    // Replicate to owning client only
    bOnlyRelevantToOwner=true
    bAlwaysRelevant=false
    RemoteRole=ROLE_SimulatedProxy
    
    Name="Default__DKMessageReplicator"
}
