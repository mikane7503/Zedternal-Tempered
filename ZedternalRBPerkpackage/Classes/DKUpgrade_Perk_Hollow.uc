class DKUpgrade_Perk_Hollow extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// ===================================================================
// HOLLOW PERK — Weapon Mastery Gauntlet System
//
// Every weapon has 5 sequential conditions to complete.
// Completing all 5 unlocks a free "Hollow" variant in the trader.
// Hollow variants have per-weapon stat boosts and no upgrade eligibility.
// Only the player who unlocked a Hollow weapon can see/buy it.
//
// Conditions (sequential per weapon):
//   0: Headshot Kills
//   1: Total Kills
//   2: Collateral Kills (multi-kill in one shot)
//   3: Rapid Kills (ranged) / Melee Kills (melee weapons)
//   4: Large Zed Kills
// ===================================================================

// Passive scaling per level
var config float DamagePerLevel;       // +2% damage per level
var config float ReloadPerLevel;       // +1.5% reload speed per level

// Condition thresholds
var config int ConditionTarget_Headshot;       // 50
var config int ConditionTarget_TotalKills;     // 200
var config int ConditionTarget_Collateral;     // 50
var config int ConditionTarget_Rapid;          // 50
var config int ConditionTarget_Melee;          // 50
var config int ConditionTarget_LargeZed;       // 50

// Collateral detection window (seconds)
var config float CollateralWindow;             // 0.05s

// Rapid kill detection
var config int RapidKillThreshold;             // 3 kills needed in window
var config float RapidKillWindow;              // 4.0s rolling window
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DamagePerLevel = 0.02f;
		default.ReloadPerLevel = 0.015f;
		default.ConditionTarget_Headshot = 50;
		default.ConditionTarget_TotalKills = 200;
		default.ConditionTarget_Collateral = 50;
		default.ConditionTarget_Rapid = 50;
		default.ConditionTarget_Melee = 50;
		default.ConditionTarget_LargeZed = 50;
		default.CollateralWindow = 0.05f;
		default.RapidKillThreshold = 3;
		default.RapidKillWindow = 4.0f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// PASSIVE BONUSES
// ===================================================================

static function ModifyDamageGivenPassive(out float damageFactor, int upgLevel)
{
    damageFactor += default.DamagePerLevel * upgLevel;
}

static simulated function GetReloadRateScalePassive(out float reloadRateFactor, int upgLevel)
{
    reloadRateFactor -= default.ReloadPerLevel * upgLevel;
}

// ===================================================================
// DAMAGE GIVEN — Kill Detection + Hollow Weapon Bonuses
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Hollow_Helper HollowHelper;
    local float HollowDmg;
    local string NormName, BehaviorMod;
    local float ShatterThreshold, RemainingHPPct;
    local int UnlockCount;

    if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None)
        return;

    // Get or spawn helper
    HollowHelper = GetHelper(DamageInstigator.Pawn);
    if (HollowHelper == None)
        return;

    // Keep helper's perk level current
    HollowHelper.PerkLevel = upgLevel;

    // === HOLLOW WEAPON SYSTEM (gated by config) ===
    if (class'DKConfig_HollowWeapons'.static.IsEnabled())
    {
        // === HOLLOW WEAPON BONUSES ===
        if (MyKFW != None && IsHollowWeapon(MyKFW))
        {
            NormName = NormalizeWeaponName(string(MyKFW.Class.Name));

            // Base stat damage bonus
            HollowDmg = class'DKHollowWeaponData'.static.GetDamageBonus(NormName);
            if (HollowDmg > 0.f)
                InDamage += Round(float(DefaultDamage) * HollowDmg);

            // === LEVEL 20: VOID MASTERY - +1% damage per unique Hollow unlock ===
            if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
            {
                UnlockCount = HollowHelper.GetUnlockCount();
                if (UnlockCount > 0)
                    InDamage += Round(float(DefaultDamage) * (float(UnlockCount) * 0.01f));
            }

            // === BEHAVIOR MOD BONUSES (on-hit) ===
            BehaviorMod = class'DKHollowWeaponData'.static.GetBehaviorMod(NormName);

            if (BehaviorMod == "executioner")
            {
                if (MyKFPM.GetHealthPercentage() < 0.4f)
                    InDamage += Round(float(DefaultDamage) * 0.50f);
            }
            else if (BehaviorMod == "precision")
            {
                if (HitZoneIdx == 0)
                    InDamage += Round(float(DefaultDamage) * 0.50f);
            }
            else if (BehaviorMod == "hemorrhage")
            {
                InDamage += Round(float(DefaultDamage) * 0.20f);
            }
            else if (BehaviorMod == "incendiary")
            {
                InDamage += Round(float(DefaultDamage) * 0.20f);
            }
            else if (BehaviorMod == "titanslayer")
            {
                if (IsLargeZed(MyKFPM))
                    InDamage += Round(float(DefaultDamage) * 0.40f);
            }

            // === LEVEL 10: CALL OF THE VOID - Shatter Point ===
            if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank1Level && InDamage < MyKFPM.Health && MyKFPM.HealthMax > 0)
            {
                ShatterThreshold = HollowHelper.GetShatterThreshold(NormName);
                if (ShatterThreshold > 0.f)
                {
                    if (MyKFPM.Class.static.IsABoss())
                        ShatterThreshold *= 0.5f;

                    RemainingHPPct = float(MyKFPM.Health - InDamage) / float(MyKFPM.HealthMax);
                    if (RemainingHPPct <= ShatterThreshold)
                    {
                        InDamage = MyKFPM.Health;
                    }
                }
            }
        }

        // Detect kills for condition tracking + on-kill behavior mods
        if (InDamage >= MyKFPM.Health)
        {
            if (MyKFW != None)
            {
                if (IsHollowWeapon(MyKFW))
                {
                    HollowHelper.ApplyOnKillBehaviorMod(MyKFW, MyKFPM, InDamage);
                }
                else
                {
                    HollowHelper.TrackWeaponKill(MyKFW, MyKFPM, HitZoneIdx, DamageType);
                }
            }
            else if (DamageType != None && DamageType.default.WeaponDef != None)
            {
                // DK FIX: weapon-originated indirect damage (afterburn / bleed
                // DoT ticks) carries no KFWeapon reference, so flame and
                // streaming weapons never credited burn-out kills. Resolve the
                // weapon from the damage type's WeaponDef instead. The
                // helper's kill dedupe prevents double counting against the
                // direct-hit path.
                HollowHelper.TrackWeaponKillByName(
                    WeaponNameFromDef(DamageType.default.WeaponDef),
                    false, MyKFPM, HitZoneIdx, DamageType);
            }
        }
    }
}

// ===================================================================
// HOLLOW WEAPON STAT BONUSES (non-damage)
// ===================================================================

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local float Bonus;

    if (KFW != None && IsHollowWeapon(KFW))
    {
        Bonus = class'DKHollowWeaponData'.static.GetReloadBonus(
            NormalizeWeaponName(string(KFW.Class.Name)));
        // INV-ADD composition matches the rest of the codebase and prevents
        // negative scale values when other reload skills also stack.
        if (Bonus > 0.f)
            InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + Bonus);
    }
}

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
    local float Bonus;
    local string NormName;

    if (KFW != None && IsHollowWeapon(KFW))
    {
        NormName = NormalizeWeaponName(string(KFW.Class.Name));

        Bonus = class'DKHollowWeaponData'.static.GetMagBonus(NormName);
        if (Bonus > 0.f)
            InMagazineCapacity += Round(float(DefaultMagazineCapacity) * Bonus);

        // Bottomless: +50% extra magazine on top of base bonus
        if (class'DKHollowWeaponData'.static.HasBehaviorMod(NormName, "bottomless"))
            InMagazineCapacity += Round(float(DefaultMagazineCapacity) * 0.50f);

        // Overcharged: -30% magazine (trade-off for fire rate)
        if (class'DKHollowWeaponData'.static.HasBehaviorMod(NormName, "overcharged"))
            InMagazineCapacity -= Round(float(DefaultMagazineCapacity) * 0.30f);
    }
}

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=False)
{
    local float Bonus;
    local string NormName;

    if (KFW != None && IsHollowWeapon(KFW))
    {
        NormName = NormalizeWeaponName(string(KFW.Class.Name));

        Bonus = class'DKHollowWeaponData'.static.GetAmmoBonus(NormName);
        if (Bonus > 0.f)
            InSpareAmmo += Round(float(DefaultSpareAmmo) * Bonus);

        // Stockpile: +100% extra spare ammo on top of base bonus
        if (class'DKHollowWeaponData'.static.HasBehaviorMod(NormName, "stockpile"))
            InSpareAmmo += Round(float(DefaultSpareAmmo) * 1.00f);

        // Bottomless: +50% extra spare ammo
        if (class'DKHollowWeaponData'.static.HasBehaviorMod(NormName, "bottomless"))
            InSpareAmmo += Round(float(DefaultSpareAmmo) * 0.50f);
    }
}

static simulated function ModifyRecoil(out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
    local float Bonus;

    if (KFW != None && IsHollowWeapon(KFW))
    {
        Bonus = class'DKHollowWeaponData'.static.GetRecoilBonus(
            NormalizeWeaponName(string(KFW.Class.Name)));
        if (Bonus > 0.f)
            InRecoilModifier -= DefaultRecoilModifier * Bonus;
    }
}

static simulated function ModifySpread(out float InSpreadModifier, float DefaultSpreadModifier, int upgLevel, KFWeapon KFW)
{
    local float Bonus;

    if (KFW != None && IsHollowWeapon(KFW))
    {
        Bonus = class'DKHollowWeaponData'.static.GetSpreadBonus(
            NormalizeWeaponName(string(KFW.Class.Name)));
        if (Bonus > 0.f)
            InSpreadModifier -= DefaultSpreadModifier * Bonus;
    }
}

static simulated function ModifyPenetration(out float InPenetration, float DefaultPenetration, int upgLevel, class<KFDamageType> DamageType, KFPawn OwnerPawn, optional bool bForce)
{
    local KFWeapon KFW;
    local float Bonus;

    if (OwnerPawn != None)
    {
        KFW = KFWeapon(OwnerPawn.Weapon);
        if (KFW != None && IsHollowWeapon(KFW))
        {
            Bonus = class'DKHollowWeaponData'.static.GetPenetrationBonus(
                NormalizeWeaponName(string(KFW.Class.Name)));
            if (Bonus > 0.f)
                InPenetration += DefaultPenetration * Bonus;
        }
    }
}

static simulated function ModifyRateOfFire(out float InRate, float DefaultRate, int upgLevel, KFWeapon KFW)
{
    local float Bonus;
    local string NormName;

    if (KFW != None && IsHollowWeapon(KFW))
    {
        NormName = NormalizeWeaponName(string(KFW.Class.Name));

        Bonus = class'DKHollowWeaponData'.static.GetRateOfFireBonus(NormName);
        if (Bonus > 0.f)
            InRate -= DefaultRate * Bonus;

        // Overcharged: +30% extra fire rate on top of base
        if (class'DKHollowWeaponData'.static.HasBehaviorMod(NormName, "overcharged"))
            InRate -= DefaultRate * 0.30f;
    }
}

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime, float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
    local string NormName;

    if (KFW != None && IsHollowWeapon(KFW))
    {
        NormName = NormalizeWeaponName(string(KFW.Class.Name));

        // Featherweight: -30% weapon switch time
        if (class'DKHollowWeaponData'.static.HasBehaviorMod(NormName, "featherweight"))
            InSwitchTime -= DefaultSwitchTime * 0.30f;
    }
}

static function ModifyStumblePower(out float InStumblePower, float DefaultStumblePower, int upgLevel, optional KFPawn KFP, optional class<KFDamageType> DamageType, optional out float CooldownModifier, optional byte BodyPart, optional KFPawn OwnerPawn)
{
    local KFWeapon KFW;
    local float Bonus;

    if (OwnerPawn != None)
    {
        KFW = KFWeapon(OwnerPawn.Weapon);
        if (KFW != None && IsHollowWeapon(KFW))
        {
            Bonus = class'DKHollowWeaponData'.static.GetStumbleBonus(
                NormalizeWeaponName(string(KFW.Class.Name)));
            if (Bonus > 0.f)
                InStumblePower += DefaultStumblePower * Bonus;
        }
    }
}

static simulated function ModifyMeleeAttackSpeed(out float InDuration, float DefaultDuration, int upgLevel, KFWeapon KFW)
{
    local float Bonus;

    if (KFW != None && IsHollowWeapon(KFW))
    {
        Bonus = class'DKHollowWeaponData'.static.GetMeleeSpeedBonus(
            NormalizeWeaponName(string(KFW.Class.Name)));
        if (Bonus > 0.f)
            InDuration -= DefaultDuration * Bonus;
    }
}

static function ModifyHardAttackDamage(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn)
{
    local KFWeapon KFW;
    local float Bonus;

    if (OwnerPawn != None)
    {
        KFW = KFWeapon(OwnerPawn.Weapon);
        if (KFW != None && IsHollowWeapon(KFW))
        {
            Bonus = class'DKHollowWeaponData'.static.GetHardAttackBonus(
                NormalizeWeaponName(string(KFW.Class.Name)));
            if (Bonus > 0.f)
                InDamage += Round(float(DefaultDamage) * Bonus);
        }
    }
}

// ModifyDoTScaler: No weapon/pawn context available in signature.
// DoT bonus is applied through the Helper's on-hit behavior mods instead.

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
    local KFWeapon KFW;
    local float Bonus;
    local string NormName;

    if (OwnerPawn != None)
    {
        KFW = KFWeapon(OwnerPawn.Weapon);
        if (KFW != None && IsHollowWeapon(KFW))
        {
            NormName = NormalizeWeaponName(string(KFW.Class.Name));

            Bonus = class'DKHollowWeaponData'.static.GetMoveSpeedBonus(NormName);
            if (Bonus > 0.f)
                InSpeed += DefaultSpeed * Bonus;

            // Featherweight: +10% extra move speed on top of base
            if (class'DKHollowWeaponData'.static.HasBehaviorMod(NormName, "featherweight"))
                InSpeed += DefaultSpeed * 0.10f;
        }
    }
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    local KFWeapon KFW;
    local float Bonus;

    if (OwnerPawn != None)
    {
        KFW = KFWeapon(OwnerPawn.Weapon);
        if (KFW != None && IsHollowWeapon(KFW))
        {
            Bonus = class'DKHollowWeaponData'.static.GetDamageResistBonus(
                NormalizeWeaponName(string(KFW.Class.Name)));
            if (Bonus > 0.f)
                InDamage -= Round(float(DefaultDamage) * Bonus);
        }
    }
}

// ===================================================================
// WEAPON NAME NORMALIZATION
// Extends Artificer pattern: also strips _Hollow suffix
// ===================================================================

static function string NormalizeWeaponName(string WeaponClassName)
{
    // Strip prefix
    if (Left(WeaponClassName, 7) ~= "KFWeap_")
        WeaponClassName = Mid(WeaponClassName, 7);
    else if (Left(WeaponClassName, 7) ~= "WMWeap_")
        WeaponClassName = Mid(WeaponClassName, 7);
    else if (Left(WeaponClassName, 7) ~= "DKWeap_")
        WeaponClassName = Mid(WeaponClassName, 7);

    // Strip suffix (check longest first)
    if (Len(WeaponClassName) > 9 && Right(WeaponClassName, 9) ~= "_Precious")
        WeaponClassName = Left(WeaponClassName, Len(WeaponClassName) - 9);
    else if (Len(WeaponClassName) > 9 && Right(WeaponClassName, 9) ~= "_Reforged")
        WeaponClassName = Left(WeaponClassName, Len(WeaponClassName) - 9);
    else if (Len(WeaponClassName) > 7 && Right(WeaponClassName, 7) ~= "_Hollow")
        WeaponClassName = Left(WeaponClassName, Len(WeaponClassName) - 7);

    return WeaponClassName;
}

// DK FIX: resolve a normalized weapon name from a damage type's WeaponDef.
// Used for DoT kills (afterburn, bleed) where no KFWeapon reference exists.
static function string WeaponNameFromDef(class<KFWeaponDefinition> WDef)
{
    local string Path;
    local int DotPos;

    if (WDef == None)
        return "";

    Path = WDef.default.WeaponClassPath;
    DotPos = InStr(Path, ".");
    if (DotPos != INDEX_NONE)
        Path = Mid(Path, DotPos + 1);

    return NormalizeWeaponName(Path);
}

// DK FIX: weapons that physically cannot score headshots (streaming sprays,
// beams, pure-explosive launchers). The helper skips the "Headshot Kills"
// condition for these and starts them on "Total Kills" instead.
static function bool CanHeadshot(string NormName)
{
    switch (Locs(NormName))
    {
        case "flame_caulkburn":
        case "flame_flamethrower":
        case "beam_microwave":
        case "ice_freezethrower":
        case "hrg_healthrower":
        case "hrg_emp_arcgenerator":
        case "shrinkraygun":
        case "hrg_locust":
        case "grenadelauncher_hx25":
        case "grenadelauncher_m32":
        case "grenadelauncher_m79":
        case "rocketlauncher_sealsqueal":
        case "thrown_c4":
        case "hrg_boomy":
        case "gravityimploder":
        case "huskcannon":
        case "mine_reconstructor":
        case "hrg_medicmissile":
        case "hrg_ballisticbouncer":
            return False;
        default:
            return True;
    }
}

// Check if a weapon is a Hollow variant
static function bool IsHollowWeapon(KFWeapon KFW)
{
    local string ClassName;

    if (KFW == None)
        return False;

    // If Hollow weapon system is disabled, no weapon is Hollow
    if (!class'DKConfig_HollowWeapons'.static.IsEnabled())
        return False;

    ClassName = string(KFW.Class.Name);
    return (Left(ClassName, 7) ~= "DKWeap_" && Len(ClassName) > 7 && Right(ClassName, 7) ~= "_Hollow");
}

// Check if a weapon is a melee weapon
static function bool IsMeleeWeapon(KFWeapon KFW)
{
    if (KFW == None)
        return False;

    return KFW.IsA('KFWeap_MeleeBase');
}

// Check if a monster is a large zed (Scrake, Fleshpound, Quarter Pound families)
static function bool IsLargeZed(KFPawn_Monster KFPM)
{
    if (KFPM == None)
        return False;

    return KFPM.IsA('KFPawn_ZedScrake')
        || KFPM.IsA('KFPawn_ZedFleshpound')
        || KFPM.IsA('KFPawn_ZedFleshpoundMini');
}

// Get the condition target count for a given condition index
static function int GetConditionTarget(int ConditionIdx, bool bIsMelee)
{
    switch (ConditionIdx)
    {
        case 0: return default.ConditionTarget_Headshot;
        case 1: return default.ConditionTarget_TotalKills;
        case 2: return default.ConditionTarget_Collateral;
        case 3:
            if (bIsMelee)
                return default.ConditionTarget_Melee;
            else
                return default.ConditionTarget_Rapid;
        case 4: return default.ConditionTarget_LargeZed;
        default: return 999999;
    }
}

// Get the condition name for HUD display
static function string GetConditionName(int ConditionIdx, bool bIsMelee)
{
    switch (ConditionIdx)
    {
        case 0: return "Headshot Kills";
        case 1: return "Total Kills";
        case 2: return "Collateral Kills";
        case 3:
            if (bIsMelee)
                return "Melee Kills";
            else
                return "Rapid Kills";
        case 4: return "Large Zed Kills";
        default: return "Complete";
    }
}

// ===================================================================
// HELPER CLASS MANAGEMENT
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Hollow_Helper HollowHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Hollow_Helper', HollowHelper)
        {
            bFound = True;
            HollowHelper.PerkLevel = upgLevel;
            break;
        }

        if (!bFound)
        {
            HollowHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Hollow_Helper', OwnerPawn);
            if (HollowHelper != None)
                HollowHelper.PerkLevel = upgLevel;
        }
    }
}

static function DKUpgrade_Perk_Hollow_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Hollow_Helper HollowHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Hollow_Helper', HollowHelper)
        {
            return HollowHelper;
        }

        // Should have one — spawn if missing
        HollowHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Hollow_Helper', OwnerPawn);
    }

    return HollowHelper;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Hollow_Helper HollowHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Hollow_Helper', HollowHelper)
        {
            HollowHelper.Destroy();
        }
    }
}

defaultproperties
{
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_Hollow]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Hollow"
    LocalizeDescriptionLineCount=5

    // Passive scaling

    // Condition thresholds

    // Collateral detection

    // Rapid kill detection

    UpgradeName="Hollow"

    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)

    UpgradeDescription(0)="<font color=\"#6B0099\">Void Conditioning:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#6B0099\">All Weapon Damage</font>"
    UpgradeDescription(1)="<font color=\"#6B0099\">Void Conditioning:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#6B0099\">Reload Speed</font>"
    UpgradeDescription(2)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Call of the Void</font> - Hollow weapon hits <font color=\"#FFFFFF\">Shatter</font> targets at low health (halved threshold on <font color=\"#6B0099\">Bosses</font>)"
    UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Void Mastery</font> - <font color=\"#FFFFFF\">+1%</font> damage with Hollow weapons per <font color=\"#6B0099\">unique unlock</font>"
    UpgradeDescription(4)="Master <font color=\"#FFFFFF\">5 conditions</font> on each weapon to unlock its <font color=\"#FFD700\">Hollow variant</font> in the trader"

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_0'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_1'
	UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_2'
	UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_3'
	UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_4'
	UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'

	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_Hollow"
}
