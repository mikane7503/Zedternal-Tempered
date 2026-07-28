// ===================================================================
// DKConfig_RoguelikePool - Roguelike upgrade pool overrides
//
// Lets server admins override the StatValue and Description of any
// roguelike upgrade, OR disable upgrades entirely from the random pool.
//
// Upgrades are identified by their UpgradeID (e.g. "UNIV_C_HEALTH").
// Default values come from DKRoguelikeUpgradeManager.LoadUpgradePools();
// admins only need to specify what they want to change.
//
// INI section: [ZedternalRBPerkpackage.DKConfig_RoguelikePool]
// File: KFZedternalUnlimited.ini
//
// Examples:
//   ; Make Toughness give +10 HP instead of +5
//   UpgradeOverride=(UpgradeID="UNIV_C_HEALTH",StatValue=10.0)
//
//   ; Buff legendary damage with a custom description
//   UpgradeOverride=(UpgradeID="UNIV_L_DAMAGE",StatValue=0.20,Description="+20% Damage Dealt")
//
//   ; Remove an upgrade from the random pool entirely
//   UpgradeOverride=(UpgradeID="UNIV_C_GLASSCANNON",bDisabled=True)
//
//   ; Disable a perk-specific Unique (mechanics still work for owners but
//   ; it won't be offered to new players)
//   UpgradeOverride=(UpgradeID="PERK_X_BERSERKER",bDisabled=True)
//
// Notes:
//   - Set StatValue to 0 (or omit it) to keep the hardcoded default.
//   - Description left empty keeps the hardcoded default.
//   - To remove an upgrade entirely, use bDisabled=True.
//   - UpgradeID matching is case-insensitive.
//   - Disabling a Unique only removes it from rolls; existing helpers
//     keep working for players who already have it.
// ===================================================================
class DKConfig_RoguelikePool extends Config_Common
    config(ZedternalUnlimited);

struct S_RoguelikeUpgradeOverride
{
    var string UpgradeID;     // Required - the upgrade to override
    var float StatValue;      // Override stat value (0 = keep hardcoded)
    var string Description;   // Override description (empty = keep hardcoded)
    var bool bDisabled;       // Remove this upgrade from the pool entirely
};

var config array<S_RoguelikeUpgradeOverride> UpgradeOverrides;
var config int MODEVERSION;

static function InitializeConfig()
{
    if (default.MODEVERSION < 1)
    {
        // No defaults seeded - admin opts in by adding UpgradeOverride entries
        default.MODEVERSION = 1;
        static.StaticSaveConfig();
    }
}

static function CheckBasicConfigValues()
{
    local int i;

    for (i = 0; i < default.UpgradeOverrides.Length; i++)
    {
        if (default.UpgradeOverrides[i].UpgradeID == "")
        {
            `log("[DK_ROGUELIKE_OVERRIDE] WARNING: UpgradeOverride entry #" $ i $ " has empty UpgradeID - will be ignored");
        }
    }
}

/** Find an override entry by UpgradeID (case-insensitive). Returns True if found. */
static function bool FindOverride(string UpgradeID, out S_RoguelikeUpgradeOverride Out)
{
    local int i;

    if (UpgradeID == "")
        return False;

    for (i = 0; i < default.UpgradeOverrides.Length; i++)
    {
        if (default.UpgradeOverrides[i].UpgradeID ~= UpgradeID)
        {
            Out = default.UpgradeOverrides[i];
            return True;
        }
    }
    return False;
}

/** Get the total number of overrides defined in INI */
static function int GetOverrideCount()
{
    return default.UpgradeOverrides.Length;
}

/** Get the UpgradeID at a specific index (for unmatched-override warnings) */
static function string GetOverrideID(int Index)
{
    if (Index >= 0 && Index < default.UpgradeOverrides.Length)
        return default.UpgradeOverrides[Index].UpgradeID;
    return "";
}

defaultproperties
{
    Name="Default__DKConfig_RoguelikePool"
}
