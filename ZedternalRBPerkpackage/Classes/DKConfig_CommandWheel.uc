// ===================================================================
// DKConfig_CommandWheel - Per-player command wheel configuration
//
// Stores 10 configurable slots matching the voice comm wheel positions.
// Empty slots keep their original voice comm function.
// Players configure via INI editing.
//
// Slot mapping to wheel positions:
//   Slot 1  = Request Healing (left-top)
//   Slot 2  = Request Dosh (left-mid)
//   Slot 3  = Request Help (left-bottom)
//   Slot 4  = Taunt Zeds (bottom-left)
//   Slot 5  = Follow Me (right-top)
//   Slot 6  = Get to Trader (right-mid)
//   Slot 7  = Affirmative (right-bottom)
//   Slot 8  = Negative (bottom-right)
//   Slot 9  = Emote (bottom-center)
//   Slot 10 = Thank You (top-center)
//
// Example populated INI entry:
//   [ZedternalRBPerkpackage.DKConfig_CommandWheel]
//   Slot_1_Label=Drop all trophies
//   Slot_1_Command=DropTrophy all
//   Slot_2_Label=Upgrade menu
//   Slot_2_Command=OpenUpgradeMenu
//   Slot_5_Label=Preset 1
//   Slot_5_Command=mutate zupreset 1
// ===================================================================
class DKConfig_CommandWheel extends Object
    config(ZedternalUnlimited_Local);

const NUM_SLOTS = 10;

var config string Slot_1_Label;
var config string Slot_1_Command;
var config string Slot_2_Label;
var config string Slot_2_Command;
var config string Slot_3_Label;
var config string Slot_3_Command;
var config string Slot_4_Label;
var config string Slot_4_Command;
var config string Slot_5_Label;
var config string Slot_5_Command;
var config string Slot_6_Label;
var config string Slot_6_Command;
var config string Slot_7_Label;
var config string Slot_7_Command;
var config string Slot_8_Label;
var config string Slot_8_Command;
var config string Slot_9_Label;
var config string Slot_9_Command;
var config string Slot_10_Label;
var config string Slot_10_Command;

static function string GetSlotLabel(byte Index)
{
    switch (Index)
    {
        case 0: return default.Slot_1_Label;
        case 1: return default.Slot_2_Label;
        case 2: return default.Slot_3_Label;
        case 3: return default.Slot_4_Label;
        case 4: return default.Slot_5_Label;
        case 5: return default.Slot_6_Label;
        case 6: return default.Slot_7_Label;
        case 7: return default.Slot_8_Label;
        case 8: return default.Slot_9_Label;
        case 9: return default.Slot_10_Label;
        default: return "";
    }
}

static function string GetSlotCommand(byte Index)
{
    switch (Index)
    {
        case 0: return default.Slot_1_Command;
        case 1: return default.Slot_2_Command;
        case 2: return default.Slot_3_Command;
        case 3: return default.Slot_4_Command;
        case 4: return default.Slot_5_Command;
        case 5: return default.Slot_6_Command;
        case 6: return default.Slot_7_Command;
        case 7: return default.Slot_8_Command;
        case 8: return default.Slot_9_Command;
        case 9: return default.Slot_10_Command;
        default: return "";
    }
}

static function bool HasSlot(byte Index)
{
    return GetSlotCommand(Index) != "";
}

defaultproperties
{
    Name="Default__DKConfig_CommandWheel"
}
