// ===================================================================
// ZTUpgradeSelectMenu - Handles Roguelike Upgrade Selection Flash UI
// Shows 3 upgrade options as pre-made PNG card images
// Card images are embedded in the SWF library with linkage = UpgradeID
// ===================================================================
class ZTUpgradeSelectMenu extends GFxMoviePlayer;

var ZTPlayerController DKPC;
var bool bMenuOpen;

// Cache the current upgrade IDs for keyboard selection
var array<string> CurrentUpgradeIDs;

// ===================================================================
// INITIALIZATION
// ===================================================================

function Init(optional LocalPlayer LocPlay)
{
    Super.Init(LocPlay);
}

// ===================================================================
// MENU CONTROL
// ===================================================================

function OpenMenu(ZTPlayerController NewOwner)
{
    DKPC = NewOwner;
    
    `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: OpenMenu called");
    
    Start();
    Advance(0.f);
    
    bMenuOpen = true;
    
    // Reset input
    if (DKPC != None && DKPC.PlayerInput != None)
    {
        DKPC.PlayerInput.ResetInput();
    }
    
    `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: Menu opened");
}

// Set the upgrade options to display (called after OpenMenu)
// UpgradeIDs: Flash loads complete card PNGs from library by ID
// AccumulatedDisplays: Pre-formatted accumulated bonus text per option
function SetUpgradeOptions(array<string> UpgradeIDs, array<string> AccumulatedDisplays)
{
    local string OptionsDataStr;
    local string AccumulatedDataStr;
    local int i;
    
    // Cache locally for keyboard selection
    CurrentUpgradeIDs = UpgradeIDs;
    
    `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: SetUpgradeOptions with " $ UpgradeIDs.Length $ " options");
    
    // Build data string for Flash: "upgradeID;upgradeID;upgradeID"
    for (i = 0; i < UpgradeIDs.Length; i++)
    {
        if (i > 0)
        {
            OptionsDataStr $= ";";
            AccumulatedDataStr $= ";";
        }
        OptionsDataStr $= UpgradeIDs[i];
        
        // Accumulated display text (may be empty if stat is 0 or N/A)
        if (i < AccumulatedDisplays.Length)
        {
            AccumulatedDataStr $= AccumulatedDisplays[i];
        }
        
        `log("[DK_ROGUELIKE_UI]   Option " $ i $ ": " $ UpgradeIDs[i] @ "| Accumulated:" @ AccumulatedDisplays[i]);
    }
    
    // Send upgrade IDs to Flash
    SetVariableString("_root.upgradeOptionsData", OptionsDataStr);
    
    // Send accumulated bonus display strings to Flash
    // Format: "text;text;text" — one per option, may be empty
    SetVariableString("_root.upgradeAccumulatedData", AccumulatedDataStr);
    
    ActionScriptVoid("_root.setUpgradeOptions");
    
    `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: Sent options='" $ OptionsDataStr $ "' accumulated='" $ AccumulatedDataStr $ "' to Flash");
}

function CloseMenu()
{
    `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: CloseMenu called");
    
    bMenuOpen = false;
    
    // Clear cached data
    CurrentUpgradeIDs.Length = 0;
    
    Close();
    
    `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: Menu closed");
}

// ===================================================================
// FLASH CALLBACKS
// ===================================================================

// Called BY Flash when an upgrade card is clicked
// SlotIndex is 0, 1, or 2
function Callback_UpgradeSelected(int SlotIndex)
{
    local ZTPlayerController TempDKPC;
    
    `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: Callback_UpgradeSelected SlotIndex=" $ SlotIndex);
    
    if (SlotIndex < 0 || SlotIndex >= CurrentUpgradeIDs.Length)
    {
        `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: ERROR - Invalid SlotIndex!");
        return;
    }
    
    if (DKPC != None)
    {
        // Store reference before CloseMenu nulls it
        TempDKPC = DKPC;
        
        // Close menu first
        CloseMenu();
        
        // Tell server about the selection
        TempDKPC.ServerSelectRoguelikeUpgrade(SlotIndex);
        
        `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: Sent selection to server");
    }
}

// Called BY Flash when an upgrade card is hovered (optional)
function Callback_UpgradeHovered(int SlotIndex)
{
    `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: Upgrade " $ SlotIndex $ " hovered");
    // Could play hover sound here
}

// ===================================================================
// KEYBOARD INPUT
// ===================================================================

event bool FilterButtonInput(int ControllerId, name ButtonName, EInputEvent InputEvent)
{
    if (InputEvent == IE_Pressed)
    {
        switch (ButtonName)
        {
            // Keys 1, 2, 3 select the upgrades
            case 'One':
                TrySelectUpgradeBySlot(0);
                return true;
            case 'Two':
                TrySelectUpgradeBySlot(1);
                return true;
            case 'Three':
                TrySelectUpgradeBySlot(2);
                return true;
            case 'Escape':
                // Block escape - must select an upgrade
                return true;
        }
    }
    
    return false;
}

// Select upgrade by slot index (0, 1, or 2)
function TrySelectUpgradeBySlot(int SlotIndex)
{
    if (SlotIndex >= 0 && SlotIndex < CurrentUpgradeIDs.Length)
    {
        `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: Keyboard selected slot " $ SlotIndex);
        Callback_UpgradeSelected(SlotIndex);
    }
    else
    {
        `log("[DK_ROGUELIKE_UI] ZTUpgradeSelectMenu: Invalid slot " $ SlotIndex);
    }
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
    MovieInfo=SwfMovie'ZedternalRBPerkpackage_Resources.UI.UpgradeSelect_SWF'
    
    bAutoPlay=true
    bCaptureInput=true
    bDisplayWithHudOff=false
    bIgnoreMouseInput=false
    bShowHardwareMouseCursor=true
    
    bMenuOpen=false
}
