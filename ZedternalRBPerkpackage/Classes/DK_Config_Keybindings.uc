// ===================================================================
// DK_Config_Keybindings - Stores default keybindings for the mod
// Auto-applies keybindings on first join, saves state per-user
// ===================================================================
class DK_Config_Keybindings extends Object
    config(ZedternalUnlimited_Local);

struct KeybindingEntry
{
    var config string KeyName;
    var config string Command;
    var config string Description;
};

// Default keybindings that will be applied on first join
var config array<KeybindingEntry> DefaultKeybindings;

// Flag to track if we've already applied defaults for this user
var config bool bHasAppliedDefaults;

static function InitializeDefaults(out DK_Config_Keybindings Config)
{
    // Initialize default keybindings if the config is empty
    if (Config.DefaultKeybindings.Length == 0)
    {
        `log("DK_Config_Keybindings: Initializing default keybindings...");
        
        Config.DefaultKeybindings.Length = 13;
        
        Config.DefaultKeybindings[0].KeyName = "F1";
        Config.DefaultKeybindings[0].Command = "OpenZedternalUpgradeMenu";
        Config.DefaultKeybindings[0].Description = "Open Upgrade Menu";
        
        Config.DefaultKeybindings[1].KeyName = "F2";
        Config.DefaultKeybindings[1].Command = "ActivateAbility1";
        Config.DefaultKeybindings[1].Description = "Activate Ability Slot 1";
        
        Config.DefaultKeybindings[2].KeyName = "F3";
        Config.DefaultKeybindings[2].Command = "ActivateAbility2";
        Config.DefaultKeybindings[2].Description = "Activate Ability Slot 2";
        
        Config.DefaultKeybindings[3].KeyName = "F4";
        Config.DefaultKeybindings[3].Command = "ActivateAbility3";
        Config.DefaultKeybindings[3].Description = "Activate Ability Slot 3";
        
        Config.DefaultKeybindings[4].KeyName = "F5";
        Config.DefaultKeybindings[4].Command = "ActivateAbility4";
        Config.DefaultKeybindings[4].Description = "Activate Ability Slot 4";
        
        Config.DefaultKeybindings[5].KeyName = "F8";
        Config.DefaultKeybindings[5].Command = "DKWheel";
        Config.DefaultKeybindings[5].Description = "Command Wheel (Trader)";
        
        Config.DefaultKeybindings[6].KeyName = "H";
        Config.DefaultKeybindings[6].Command = "ActivateHyde";
        Config.DefaultKeybindings[6].Description = "Hyde Serum (Jekyll & Hyde perk)";
        
        Config.DefaultKeybindings[7].KeyName = "L";
        Config.DefaultKeybindings[7].Command = "DomainPress | OnRelease DomainRelease";
        Config.DefaultKeybindings[7].Description = "Domain (press to cast / hold for ability wheel)";
        
        Config.DefaultKeybindings[8].KeyName = "U";
        Config.DefaultKeybindings[8].Command = "ActivateSpeedster";
        Config.DefaultKeybindings[8].Description = "Blink Strike (Speedster perk)";
        
        Config.DefaultKeybindings[9].KeyName = "O";
        Config.DefaultKeybindings[9].Command = "PossessorPress";
        Config.DefaultKeybindings[9].Description = "Possession (Possessor perk)";

        Config.DefaultKeybindings[10].KeyName = "J";
        Config.DefaultKeybindings[10].Command = "PuppetMortar";
        Config.DefaultKeybindings[10].Description = "Possessed Patriarch: mortar barrage";

        Config.DefaultKeybindings[11].KeyName = "K";
        Config.DefaultKeybindings[11].Command = "PuppetMissile";
        Config.DefaultKeybindings[11].Description = "Possessed Patriarch: missile barrage";

        Config.DefaultKeybindings[12].KeyName = "P";
        Config.DefaultKeybindings[12].Command = "PuppetHeal";
        Config.DefaultKeybindings[12].Description = "Possessed Patriarch: self-heal";

        Config.SaveConfig();
        
        `log("DK_Config_Keybindings: Default keybindings initialized and saved");
    }
    else
    {
        // Migration: ensure newer default binds (added in later mod versions)
        // are present for users whose saved config predates them.
        EnsureBind(Config, "H", "ActivateHyde", "Hyde Serum (Jekyll & Hyde perk)");
        EnsureBind(Config, "L", "DomainPress | OnRelease DomainRelease", "Domain (press to cast / hold for ability wheel)");
        EnsureBind(Config, "U", "ActivateSpeedster", "Blink Strike (Speedster perk)");
        EnsureBind(Config, "O", "PossessorPress", "Possession (Possessor perk)");
        EnsureBind(Config, "J", "PuppetMortar", "Possessed Patriarch: mortar barrage");
        EnsureBind(Config, "K", "PuppetMissile", "Possessed Patriarch: missile barrage");
        EnsureBind(Config, "P", "PuppetHeal", "Possessed Patriarch: self-heal");
        Config.SaveConfig();
        `log("DK_Config_Keybindings: Migration pass complete (ensured default binds)");
    }
}

// Appends a default bind if no existing entry already uses that Command.
// Returns true if a new entry was added (caller should SaveConfig).
static function bool EnsureBind(out DK_Config_Keybindings Config, string KeyName, string Command, string Description)
{
    local int i;
    local KeybindingEntry NewEntry;

    for (i = 0; i < Config.DefaultKeybindings.Length; i++)
    {
        if (Config.DefaultKeybindings[i].Command ~= Command)
            return false;
    }

    NewEntry.KeyName = KeyName;
    NewEntry.Command = Command;
    NewEntry.Description = Description;
    Config.DefaultKeybindings.AddItem(NewEntry);
    return true;
}

defaultproperties
{
}
