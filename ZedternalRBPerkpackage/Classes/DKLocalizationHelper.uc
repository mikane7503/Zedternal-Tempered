// ===================================================================
// DKLocalizationHelper - shared localization lookup with English fallback
// ===================================================================
// Used by DKUpgrade_Perk / DKUpgrade_Skill / DKUpgrade_Weapon (and any
// other DK-side class that wants the smart-fallback pattern).
//
// Behavior:
//   - If Pkg and Sec are both non-empty, try native UE3 Localize().
//   - Native Localize() returns a wrapped key string (e.g.
//     "?Section?Key?Pkg?") on miss. Detect via leading '?' or empty result.
//   - On miss, return the supplied Fallback (typically the English literal
//     from default.UpgradeName / default.upgradeDescription[N]).
//
// This means localization is OPTIONAL for the player: if no .int is
// installed in KFGame/Localization/<lang>/, every DK upgrade renders the
// English defaults baked into the .uc file. No breaking change for users
// who don't install loc files.
// ===================================================================
class DKLocalizationHelper extends Object;

static function string TryLocalize(string Pkg, string Sec, string KeyName, string Fallback)
{
    local string Result;

    if (Pkg != "" && Sec != "")
    {
        Result = Localize(Sec, KeyName, Pkg);
        // Native Localize() returns "?Section?Key?Pkg?" when lookup fails.
        // Detect via leading '?' or empty result, fall through to fallback.
        if (Result != "" && Left(Result, 1) != "?")
            return Result;
    }

    return Fallback;
}

defaultproperties
{
    Name="Default__DKLocalizationHelper"
}
