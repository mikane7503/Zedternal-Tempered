// ===================================================================
// ZTCommandWheelMovie - Standalone GFxMoviePlayer for command wheel
//
// Loads CommandWheel.swf as a full-screen overlay during trader time.
// Pushes slot data from ZTConfig_CommandWheel to Flash.
// Receives selection callback from Flash and executes console commands.
//
// Input: Mouse to highlight, left-click to execute, Escape/right-click to close.
// ===================================================================
class ZTCommandWheelMovie extends GFxMoviePlayer;

var ZTPlayerController DKPC;

// ===================================================================
// INITIALIZATION
// ===================================================================

function Init(optional LocalPlayer LocPlay)
{
    Super.Init(LocPlay);
}

// ===================================================================
// OPEN / CLOSE
// ===================================================================

function bool OpenWheel(ZTPlayerController NewOwner)
{
    DKPC = NewOwner;

    if (MovieInfo == None)
    {
        `log("[DK] CommandWheel: MovieInfo is None - ZedternalTempered_Menus.upk not found!");
        return false;
    }

    Start();
    Advance(0.f);

    PushAllSlotData();

    if (DKPC != None && DKPC.PlayerInput != None)
    {
        DKPC.PlayerInput.ResetInput();
    }

    return true;
}

function CloseWheel()
{
    Close(false);

    if (DKPC != None)
    {
        DKPC.CommandWheelMovie = None;
        DKPC = None;
    }
}

// ===================================================================
// SLOT DATA
// ===================================================================

function PushAllSlotData()
{
    local byte i;
    local string Label, Cmd;

    for (i = 0; i < 10; i++)
    {
        Label = class'ZTConfig_CommandWheel'.static.GetSlotLabel(i);
        Cmd = class'ZTConfig_CommandWheel'.static.GetSlotCommand(i);

        SetVariableString("_root.slotLabel" $ i, Label);
        SetVariableString("_root.slotCmd" $ i, Cmd);

        if (Label != "" || Cmd != "")
            `log("[DK_WHEEL] Slot" @ i @ "Label='" $ Label $ "' Cmd='" $ Cmd $ "'");
    }

    SetVariableBool("_root.dataReady", true);
    `log("[DK_WHEEL] PushAllSlotData complete via SetVariable");
}

// ===================================================================
// FLASH CALLBACKS
// ===================================================================

// Called from Flash via ExternalInterface.call("Callback_SlotSelected", index)
function Callback_SlotSelected(int SlotIndex)
{
    local string Cmd;

    if (SlotIndex >= 0 && SlotIndex < 10)
    {
        Cmd = class'ZTConfig_CommandWheel'.static.GetSlotCommand(SlotIndex);
        if (Cmd != "")
        {
            DKPC.ConsoleCommand(Cmd);
        }
    }

    CloseWheel();
}

// ===================================================================
// INPUT
// ===================================================================

event bool FilterButtonInput(int ControllerId, name ButtonName, EInputEvent InputEvent)
{
    if (InputEvent == IE_Pressed)
    {
        if (ButtonName == 'Escape' || ButtonName == 'XboxTypeS_B' || ButtonName == 'RightMouseButton')
        {
            CloseWheel();
            return true;
        }
    }
    return false;
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
    MovieInfo=SwfMovie'ZedternalTempered_Menus.CommandWheel_SWF'

    bAutoPlay=true
    bCaptureInput=true
    bDisplayWithHudOff=false
    bIgnoreMouseInput=false
    bShowHardwareMouseCursor=true
}
