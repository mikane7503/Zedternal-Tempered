class ZTUpgrade_Perk_Artificer extends ZTUpgrade_Perk config(ZedternalUnlimited);

// ===================================================================
// ARTIFICER PERK ? Reforged Weapon Mastery System
//
// Level 1-9:  Forge Conditioning (passive damage/reload + reforge unlocks)
// Level 10:   Weapon Mastery (100-kill milestones -> random stat rolls)
// Level 11-19: Enhanced Mastery (more rolls per milestone)
// Level 20:   Resonance (Reforged kills count double, cross-weapon damage)
// ===================================================================

// Passive scaling per level
var config float DamagePerLevel;       // +2.5% damage per level
var config float ReloadPerLevel;       // +2% reload speed per level

// Reforge unlock thresholds per perk level (Level 1-9)
// Index 0 = Level 1, Index 8 = Level 9
var config array<int> ReforgeThreshold;

// Mastery configuration
var config int MasteryMilestoneKills;  // Kills per mastery milestone (100)
var config float MasteryBonusPerRoll;  // Stat bonus per random roll (+2%)
var config float ResonanceCrossBonus;  // Cross-weapon damage per mastered weapon (+1%)
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DamagePerLevel = 0.025f;
		default.ReloadPerLevel = 0.02f;
		default.ReforgeThreshold[0] = 750;
		default.ReforgeThreshold[1] = 720;
		default.ReforgeThreshold[2] = 690;
		default.ReforgeThreshold[3] = 655;
		default.ReforgeThreshold[4] = 625;
		default.ReforgeThreshold[5] = 595;
		default.ReforgeThreshold[6] = 565;
		default.ReforgeThreshold[7] = 530;
		default.ReforgeThreshold[8] = 500;
		default.MasteryMilestoneKills = 100;
		default.MasteryBonusPerRoll = 0.02f;
		default.ResonanceCrossBonus = 0.01f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 2)
	{
		default.ReforgeThreshold[0] = 750;
		default.ReforgeThreshold[1] = 720;
		default.ReforgeThreshold[2] = 690;
		default.ReforgeThreshold[3] = 655;
		default.ReforgeThreshold[4] = 625;
		default.ReforgeThreshold[5] = 595;
		default.ReforgeThreshold[6] = 565;
		default.ReforgeThreshold[7] = 530;
		default.ReforgeThreshold[8] = 500;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.DamagePerLevel = 0.010000f;
		default.ReloadPerLevel = 0.010000f;
		default.ReforgeThreshold.Length = 9;
		default.ReforgeThreshold[0] = 350;
		default.ReforgeThreshold[1] = 320;
		default.ReforgeThreshold[2] = 290;
		default.ReforgeThreshold[3] = 255;
		default.ReforgeThreshold[4] = 225;
		default.ReforgeThreshold[5] = 195;
		default.ReforgeThreshold[6] = 165;
		default.ReforgeThreshold[7] = 130;
		default.ReforgeThreshold[8] = 100;
		default.MasteryMilestoneKills = 100;
		default.MasteryBonusPerRoll = 0.005000f;
		default.ResonanceCrossBonus = 0.002500f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// PASSIVE BONUSES (called once per tick, cached)
// ===================================================================

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
    damageFactor += default.DamagePerLevel * upgLevel;
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
    // Negative = faster reload
    reloadRateFactor -= default.ReloadPerLevel * upgLevel;
}

// ===================================================================
// DAMAGE GIVEN ? Kill Detection & Mastery Bonus Application
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local string NormName;
    local float MasteryDmg, ResonanceDmg;

    if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None)
        return;

    // Get or spawn helper
    ArtHelper = GetHelper(DamageInstigator.Pawn);
    if (ArtHelper == None)
        return;

    // Keep helper's perk level current
    ArtHelper.PerkLevel = upgLevel;

    // Apply mastery damage bonus if Level 10+
    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && MyKFW != None)
    {
        NormName = NormalizeWeaponName(string(MyKFW.Class.Name));
        MasteryDmg = ArtHelper.GetMasteryBonus(NormName, 0); // stat index 0 = damage
        if (MasteryDmg > 0.f)
            InDamage += Round(float(DefaultDamage) * MasteryDmg);

        // Level 20 Resonance: cross-weapon damage bonus
        if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level)
        {
            ResonanceDmg = ArtHelper.GetResonanceBonus();
            if (ResonanceDmg > 0.f)
                InDamage += Round(float(DefaultDamage) * ResonanceDmg);
        }
    }

    // Kill tracking moved to Killed() in GameInfo for 100% accuracy.
    // ModifyDamageGiven is a damage modifier, not a kill hook ? it misses
    // multikills, explosions, DoT, penetration, and turret kills.
}

// ===================================================================
// MASTERY STAT APPLICATION (non-damage stats)
// ===================================================================

// Mastery reload speed bonus (stat index 1)
static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local float Bonus;

    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && KFW != None && OwnerPawn != None)
    {
        ArtHelper = GetHelper(OwnerPawn);
        if (ArtHelper != None)
        {
            Bonus = ArtHelper.GetMasteryBonus(NormalizeWeaponName(string(KFW.Class.Name)), 1);
            if (Bonus > 0.f)
                InReloadRateScale -= Bonus; // negative = faster reload
        }
    }
}

// Mastery magazine capacity bonus (stat index 2)
static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local float Bonus;

    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && KFW != None && KFW.Owner != None)
    {
        ArtHelper = GetHelper(Pawn(KFW.Owner));
        if (ArtHelper != None)
        {
            Bonus = ArtHelper.GetMasteryBonus(NormalizeWeaponName(string(KFW.Class.Name)), 2);
            if (Bonus > 0.f)
                InMagazineCapacity += Round(float(DefaultMagazineCapacity) * Bonus);
        }
    }
}

// Mastery spare ammo bonus (stat index 3)
static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=False)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local float Bonus;

    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && KFW != None && KFW.Owner != None)
    {
        ArtHelper = GetHelper(Pawn(KFW.Owner));
        if (ArtHelper != None)
        {
            Bonus = ArtHelper.GetMasteryBonus(NormalizeWeaponName(string(KFW.Class.Name)), 3);
            if (Bonus > 0.f)
                InSpareAmmo += Round(float(DefaultSpareAmmo) * Bonus);
        }
    }
}

// Mastery recoil reduction bonus (stat index 4)
static simulated function ModifyRecoil(out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local float Bonus;

    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && KFW != None && KFW.Owner != None)
    {
        ArtHelper = GetHelper(Pawn(KFW.Owner));
        if (ArtHelper != None)
        {
            Bonus = ArtHelper.GetMasteryBonus(NormalizeWeaponName(string(KFW.Class.Name)), 4);
            if (Bonus > 0.f)
                InRecoilModifier -= Bonus; // negative = less recoil
        }
    }
}

// Mastery spread reduction bonus (stat index 5)
static simulated function ModifySpread(out float InSpreadModifier, float DefaultSpreadModifier, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local float Bonus;

    if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level && KFW != None && KFW.Owner != None)
    {
        ArtHelper = GetHelper(Pawn(KFW.Owner));
        if (ArtHelper != None)
        {
            Bonus = ArtHelper.GetMasteryBonus(NormalizeWeaponName(string(KFW.Class.Name)), 5);
            if (Bonus > 0.f)
                InSpreadModifier -= Bonus; // negative = tighter spread
        }
    }
}

// Mastery penetration bonus (stat index 6)
static simulated function ModifyPenetration(out float InPenetration, float DefaultPenetration, int upgLevel, class<KFDamageType> DamageType, KFPawn OwnerPawn, optional bool bForce)
{
    // Penetration bonus applies globally via the highest mastered weapon
    // Skipped for now ? would need weapon reference which isn't available here
    // Can be added via ExtensionFunc if needed
}

// ===================================================================
// KILL NOTIFICATION ? Called from GameInfo.Killed() for every confirmed zed death
// This is the authoritative kill hook. Resolves weapon from DamageType,
// finds the Artificer helper, and routes the kill notification.
// ===================================================================

static function NotifyZedKilled(Controller Killer, Pawn KilledPawn, class<DamageType> DT)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local KFPawn_Human KFPH;
    local class<KFDamageType> KFDT;
    local class<KFWeaponDefinition> WeapDef;
    local string WeaponClassName, NormName;
    local int DotIdx;
    local bool bIsReforged;

    if (Killer == None || Killer.Pawn == None || KFPawn_Monster(KilledPawn) == None)
        return;

    KFPH = KFPawn_Human(Killer.Pawn);
    if (KFPH == None)
        return;

    // Find helper ? if none exists, player doesn't have Artificer perk
    // IMPORTANT: Use FindHelper (non-spawning) not GetHelper (which auto-spawns)
    ArtHelper = FindHelper(KFPH);
    if (ArtHelper == None)
        return;

    // Resolve weapon class name from DamageType chain
    WeaponClassName = "";
    KFDT = class<KFDamageType>(DT);
    if (KFDT != None)
    {
        WeapDef = KFDT.default.WeaponDef;
        if (WeapDef != None && WeapDef.default.WeaponClassPath != "")
        {
            // Extract class name from path: "KFGameContent.KFWeap_AssaultRifle_AK12" -> "KFWeap_AssaultRifle_AK12"
            DotIdx = InStr(WeapDef.default.WeaponClassPath, ".");
            if (DotIdx != INDEX_NONE)
                WeaponClassName = Mid(WeapDef.default.WeaponClassPath, DotIdx + 1);
            else
                WeaponClassName = WeapDef.default.WeaponClassPath;
        }
    }

    // Fallback: use killer's currently held weapon
    if (WeaponClassName == "" && KFPH.Weapon != None)
        WeaponClassName = string(KFPH.Weapon.Class.Name);

    // Still nothing ? can't attribute this kill
    if (WeaponClassName == "")
        return;

    // Skip Hollow weapon kills ? separate perk system, not tracked by Artificer
    if (Len(WeaponClassName) > 7 && Right(WeaponClassName, 7) ~= "_Hollow")
        return;

    // Check reforged status BEFORE normalization strips the suffix
    bIsReforged = (Len(WeaponClassName) > 9 && Right(WeaponClassName, 9) ~= "_Reforged");

    // Normalize to canonical base name
    NormName = NormalizeWeaponName(WeaponClassName);

    // Route to helper
    ArtHelper.NotifyConfirmedKill(NormName, bIsReforged);
}

// ===================================================================
// WEAPON NAME NORMALIZATION
// Converts any weapon variant to a canonical base identifier
// KFWeap_AssaultRifle_AK12           -> "AssaultRifle_AK12"
// WMWeap_AssaultRifle_AK12_Precious  -> "AssaultRifle_AK12"
// ZTWeap_AssaultRifle_AK12_Reforged  -> "AssaultRifle_AK12"
// ===================================================================

static function string NormalizeWeaponName(string WeaponClassName)
{
    local int Idx;

    // Strip any prefix ending in "Weap_" (handles KFWeap_, WMWeap_, DKWeap_,
    // HowdyWeap_, PsyWeap_, ZRWeap_, and any future mod prefixes)
    Idx = InStr(WeaponClassName, "Weap_");
    if (Idx != INDEX_NONE)
        WeaponClassName = Mid(WeaponClassName, Idx + 5);

    // Strip known suffixes
    if (Len(WeaponClassName) > 9 && Right(WeaponClassName, 9) ~= "_Precious")
        WeaponClassName = Left(WeaponClassName, Len(WeaponClassName) - 9);
    else if (Len(WeaponClassName) > 9 && Right(WeaponClassName, 9) ~= "_Reforged")
        WeaponClassName = Left(WeaponClassName, Len(WeaponClassName) - 9);
    else if (Len(WeaponClassName) > 7 && Right(WeaponClassName, 7) ~= "_Hollow")
        WeaponClassName = Left(WeaponClassName, Len(WeaponClassName) - 7);

    // Map turret sub-weapons to their launcher equivalents
    // so turret kills count toward the launcher's reforge/mastery progress
    if (WeaponClassName ~= "AutoTurretWeapon")
        return "AutoTurret";
    if (WeaponClassName ~= "HRG_WarthogWeapon")
        return "HRG_Warthog";

    return WeaponClassName;
}

// Check if a Reforged variant exists for a normalized weapon name
static function bool HasReforgedVariant(string NormName)
{
    local string ReforgedPath;

    ReforgedPath = "ZedternalTempered.DKWeap_" $ NormName $ "_Reforged";
    return (DynamicLoadObject(ReforgedPath, class'Class', True) != None);
}

// Check if a weapon is a Reforged variant
static function bool IsReforgedWeapon(KFWeapon KFW)
{
    local string ClassName;

    if (KFW == None)
        return False;

    ClassName = string(KFW.Class.Name);
    return (Left(ClassName, 7) ~= "DKWeap_" && Len(ClassName) > 9 && Right(ClassName, 9) ~= "_Reforged");
}

// Check if a weapon is a Hollow variant (excluded from Artificer tracking)
static function bool IsHollowWeapon(KFWeapon KFW)
{
    local string ClassName;

    if (KFW == None)
        return False;

    ClassName = string(KFW.Class.Name);
    return (Left(ClassName, 7) ~= "DKWeap_" && Len(ClassName) > 7 && Right(ClassName, 7) ~= "_Hollow");
}

// Get the reforge kill threshold for a given perk level
static function int GetReforgeThresholdForLevel(int upgLevel)
{
    if (upgLevel <= 0)
        return 999999; // effectively infinite
    if (upgLevel > default.ReforgeThreshold.Length)
        return default.ReforgeThreshold[default.ReforgeThreshold.Length - 1];

    return default.ReforgeThreshold[upgLevel - 1];
}

// Get number of mastery rolls per milestone for a given perk level
static function int GetMasteryRollCount(int upgLevel)
{
    if (upgLevel < class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
        return 0;

    // 1 + (level - 10) / 3 using integer division
    // L10-12: 1, L13-15: 2, L16-18: 3, L19-20: 4
    return 1 + (upgLevel - 10) / 3;
}

// ===================================================================
// HELPER CLASS MANAGEMENT
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Artificer_Helper', ArtHelper)
        {
            bFound = True;
            ArtHelper.PerkLevel = upgLevel;
            break;
        }

        if (!bFound)
        {
            ArtHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Artificer_Helper', OwnerPawn);
            if (ArtHelper != None)
            {
                ArtHelper.PerkLevel = upgLevel;
                // Check existing kills against new thresholds (dynamic detection)
                ArtHelper.RecheckAllThresholds();
            }
        }
    }
}

// Non-spawning helper lookup ? returns None if player doesn't have Artificer
// Used by NotifyZedKilled to avoid creating helpers for non-Artificer players
static function ZTUpgrade_Perk_Artificer_Helper FindHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;

    if (KFPawn_Human(OwnerPawn) == None)
        return None;

    foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Artificer_Helper', ArtHelper)
    {
        return ArtHelper;
    }

    return None;
}

// Auto-spawning helper lookup ? creates helper if missing (used by damage/stat hooks)
static function ZTUpgrade_Perk_Artificer_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Artificer_Helper', ArtHelper)
        {
            return ArtHelper;
        }

        // Should have one ? spawn if missing
        ArtHelper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Artificer_Helper', OwnerPawn);
    }

    return ArtHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Artificer_Helper ArtHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Artificer_Helper', ArtHelper)
        {
            ArtHelper.Destroy();
        }
    }
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Artificer_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Artificer]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Artificer"
    LocalizeDescriptionLineCount=5

    // Passive scaling

    // Reforge unlock thresholds (Level 1-9)

    // Mastery system

    // Perk name (not localized for custom perks)
    UpgradeName="Artificer"

    // PerkBonus for UI display
    // %x gets replaced by GetBonusValue(index, level) = baseValue + incValue * level
    PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)    // Damage %
    PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)    // Reload speed %
    PerkBonus(2)=(baseValue=1, incValue=0, maxValue=1)     // Rounded UI summary; exact value is 0.5%
    PerkBonus(3)=(baseValue=1, incValue=0, maxValue=1)     // Rounded UI summary; exact value is 0.25%

    // Upgrade descriptions (rich text for UI)
    // NOTE: Use ASCII-safe characters only ? Unicode symbols garble in KF2 Scaleform UI
    UpgradeDescription(0)="<font color=\"#FFD700\">Forge Conditioning:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FFD700\">All Weapon Damage</font>"
    UpgradeDescription(1)="<font color=\"#FFD700\">Forge Conditioning:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FFD700\">Reload Speed</font>"
    UpgradeDescription(2)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Weapon Mastery</font> - Every <font color=\"#FFFFFF\">100 kills</font> with a weapon earns a random <font color=\"#FFFFFF\">+0.5%</font> stat bonus. Each rank past 10 grants <font color=\"#FFFFFF\">extra rolls</font> per milestone"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Resonance</font> - <font color=\"#FFD700\">Reforged</font> kills count double. Each mastered weapon gives <font color=\"#FFFFFF\">+0.25%</font> damage with <font color=\"#FFD700\">ALL weapons</font>"
    UpgradeDescription(4)="Each rank unlocks <font color=\"#FFD700\">Reforged variants</font> sooner (<font color=\"#FFFFFF\">350</font> kills at rank 1, down to <font color=\"#FFFFFF\">100</font> at rank 9)"

    // Icons (placeholder ? replace with actual Artificer textures)

	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Artificer"
}
