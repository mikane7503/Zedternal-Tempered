class DKUpgrade_Perk_Omen extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// ===================================================================
// Omen - "The Prophet's Gambit"
//
// Each wave presents a Prophecy: a behavioral discipline challenge.
// Complete it for a permanent player buff. Fail and suffer a personal
// curse at double strength. The longer the match, the more the Omen
// has shaped your fate - for better or worse.
//
// Per-Level Passives:
//   +2% damage per level (Omen's Gaze)
//   +1% damage resistance per level (Dark Resilience)
//   +2% headshot damage per level (Fated Precision)
//
// Level 10: Tier 2 prophecies added, Cryptic Whisper, Doom Resilience
// Level 20: Tier 3 prophecies added, Deny Fate, Prophet's Accumulation
// ===================================================================

// Per-level scaling
var config float Damage;           // +2% per level
var config float DamageResist;     // +1% per level
var config float HeadshotDamage;   // +2% per level
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Damage = 0.02f;
		default.DamageResist = 0.01f;
		default.HeadshotDamage = 0.02f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// DAMAGE GIVEN
// Applies: per-level damage, per-level headshot, accumulated rewards,
//          Doom Resilience temp buff, and routes to helper for
//          prophecy condition checking
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
    optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
    optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
    optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Omen_Helper H;
    local KFPawn_Human KFPH;
    local float TotalBonus;
    local float AccMult;

    if (DamageInstigator == None)
        return;

    KFPH = KFPawn_Human(DamageInstigator.Pawn);
    if (KFPH == None)
        return;

    // --- Per-level passive: +2% damage per level ---
    TotalBonus = default.Damage * float(upgLevel);

    // --- Per-level passive: +2% headshot damage per level ---
    if (HitZoneIdx == HZI_HEAD)
        TotalBonus += default.HeadshotDamage * float(upgLevel);

    H = GetHelper(KFPH);
    if (H != None)
    {
        // Prophet's Accumulation multiplier (Level 20: +50% to all accumulated buffs)
        AccMult = 1.0f;
        if (upgLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
            AccMult = 1.5f;

        // Accumulated damage bonus (can be negative from doom)
        TotalBonus += H.AccDamage * AccMult;

        // Accumulated headshot damage bonus (can be negative from doom)
        if (HitZoneIdx == HZI_HEAD)
            TotalBonus += H.AccHeadshotDamage * AccMult;

        // Level 10: Doom Resilience temp buff (+15% damage for 20s after doom)
        if (H.bDoomResilienceActive)
            TotalBonus += 0.15f;

        // Apply total bonus with safety floor (never below 20% of default damage)
        InDamage += Round(float(DefaultDamage) * TotalBonus);
        if (InDamage < Round(float(DefaultDamage) * 0.2f))
            InDamage = Round(float(DefaultDamage) * 0.2f);

        // --- Route to helper for prophecy condition checking ---
        // Must happen AFTER damage calculation so InDamage reflects final value
        if (MyKFPM != None)
        {
            H.OnDamageGiven(InDamage, DefaultDamage, MyKFPM, DamageType, HitZoneIdx, MyKFW);
        }
    }
    else
    {
        InDamage += Round(float(DefaultDamage) * TotalBonus);
    }
}

// ===================================================================
// DAMAGE TAKEN
// Applies: per-level damage resistance, accumulated resistance,
//          and routes to helper for Untouched prophecy detection
// ===================================================================
static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel,
    KFPawn OwnerPawn, optional class<DamageType> DamageType,
    optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Omen_Helper H;
    local float TotalResist;
    local float AccMult;

    // Per-level passive: +1% DR per level
    TotalResist = default.DamageResist * float(upgLevel);

    H = GetHelper(OwnerPawn);
    if (H != None)
    {
        AccMult = 1.0f;
        if (H.CurrentUpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
            AccMult = 1.5f;

        // Accumulated DR (can be negative from doom - makes you take MORE damage)
        TotalResist += H.AccDamageResist * AccMult;

        InDamage -= Round(float(DefaultDamage) * TotalResist);
        if (InDamage < 0)
            InDamage = 0;

        // Route to helper: Untouched prophecy detection
        if (InDamage > 0)
            H.OnDamageTaken();
    }
    else
    {
        InDamage -= Round(float(DefaultDamage) * TotalResist);
        if (InDamage < 0)
            InDamage = 0;
    }
}

// ===================================================================
// MOVEMENT SPEED - accumulated move speed bonus
// ===================================================================
static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed,
    int upgLevel, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Omen_Helper H;
    local float AccMult;

    H = GetHelper(OwnerPawn);
    if (H != None && H.AccMoveSpeed != 0.0f)
    {
        AccMult = 1.0f;
        if (H.CurrentUpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
            AccMult = 1.5f;

        InSpeed += DefaultSpeed * (H.AccMoveSpeed * AccMult);

        // Safety floor: never below 60% of default speed
        if (InSpeed < DefaultSpeed * 0.6f)
            InSpeed = DefaultSpeed * 0.6f;
    }
}

// ===================================================================
// RELOAD SPEED - accumulated reload speed bonus
// Also routes to helper for Iron Discipline prophecy detection
// ===================================================================
static simulated function GetReloadRateScale(out float InReloadRateScale,
    int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Omen_Helper H;
    local float AccMult;

    H = GetHelper(OwnerPawn);
    if (H != None)
    {
        if (H.AccReloadSpeed != 0.0f)
        {
            AccMult = 1.0f;
            if (H.CurrentUpgradeLevel >= class'DKConfig_Capstone'.default.Capstone_Rank2Level)
                AccMult = 1.5f;

            // Negative AccReloadSpeed from doom INCREASES reload time
            InReloadRateScale -= H.AccReloadSpeed * AccMult;
            if (InReloadRateScale < 0.3f)
                InReloadRateScale = 0.3f;
            if (InReloadRateScale > 2.0f)
                InReloadRateScale = 2.0f;
        }

        // Route to helper: Iron Discipline reload detection (server only)
        if (OwnerPawn != None && OwnerPawn.Role == ROLE_Authority && KFW != None)
            H.OnReload(KFW);
    }
}

// ===================================================================
// MAX HEALTH - accumulated from prophecy rewards
// ===================================================================
static function ModifyHealth(out int InHealth, int DefaultHealth, int upgLevel)
{
    // Health bonus is applied directly via helper in the helper's timer
    // because ModifyHealth doesn't have an OwnerPawn parameter to get the helper.
    // Instead, the helper modifies the pawn's HealthMax directly.
}

// ===================================================================
// MAX ARMOR - accumulated from prophecy rewards
// ===================================================================
static function ModifyArmor(out int MaxArmor, int DefaultArmor, int upgLevel)
{
    // Same as health - applied directly by the helper.
}

// ===================================================================
// HEALING - route to helper for Stoneskin prophecy detection
// ===================================================================
static function ModifyHealAmount(out float InHealAmount, float DefaultHealAmount, int upgLevel)
{
    // Can't get OwnerPawn from this signature, so Stoneskin detection
    // is handled via HealingDamage instead
}

static function HealingDamage(int upgLevel, int HealAmount, KFPawn HealedPawn,
    KFPawn InstigatorPawn, class<DamageType> DamageType)
{
    local DKUpgrade_Perk_Omen_Helper H;

    if (HealedPawn != None)
    {
        H = GetHelper(HealedPawn);
        if (H != None)
            H.OnHealed();
    }
}

// ===================================================================
// WAVE END - trigger prophecy resolution
// ===================================================================
static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local DKUpgrade_Perk_Omen_Helper H;

    if (KFPC != None && KFPC.Pawn != None)
    {
        H = GetHelper(KFPC.Pawn);
        if (H != None)
            H.OnWaveEnd(upgLevel);
    }
}

// ===================================================================
// HELPER CLASS MANAGEMENT (Reaper/Predator pattern)
// ===================================================================
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Omen_Helper OmenHelper;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Omen_Helper', OmenHelper)
        {
            bFound = True;
            OmenHelper.SetUpgradeLevel(upgLevel);
            break;
        }

        if (!bFound)
        {
            OmenHelper = OwnerPawn.Spawn(class'DKUpgrade_Perk_Omen_Helper', OwnerPawn);
            if (OmenHelper != None)
                OmenHelper.Initialize(KFPawn_Human(OwnerPawn), upgLevel);
        }
    }
}

static function DKUpgrade_Perk_Omen_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Omen_Helper OmenHelper;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Omen_Helper', OmenHelper)
        {
            return OmenHelper;
        }
    }

    // Do NOT spawn here — only InitiateWeapon spawns with proper Initialize()
    return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Omen_Helper OmenHelper;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Omen_Helper', OmenHelper)
        {
            OmenHelper.Cleanup();
            OmenHelper.Destroy();
        }
    }
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================
defaultproperties
{

    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_Omen]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Omen"
    LocalizeDescriptionLineCount=6

    UpgradeName="Omen"
    UpgradeDescription(0)="<font color=\"#ebc034\">Omen's Gaze:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#ebc034\">Damage</font>"
    UpgradeDescription(1)="<font color=\"#ebc034\">Dark Resilience:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#ebc034\">Damage Resistance</font>"
    UpgradeDescription(2)="<font color=\"#ebc034\">Fated Precision:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#ebc034\">Headshot Damage</font>"
    UpgradeDescription(3)="<font color=\"#ebc034\">Prophecy:</font> Each wave, receive a <font color=\"#77d914\">Blessing</font> challenge. Complete it for a <font color=\"#15d7fa\">permanent buff</font>. Fail and suffer a <font color=\"#ff0000\">personal curse at double strength</font>."
    UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Visions of Dread</font> - Harder prophecies added. Failing a prophecy grants <font color=\"#15d7fa\">Doom Resilience</font> (<font color=\"#FFFFFF\">+15%</font> damage for <font color=\"#FFFFFF\">20s</font>)."
    UpgradeDescription(5)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Architect of Fate</font> - Extreme prophecies added. <font color=\"#15d7fa\">Deny Fate</font> once per <font color=\"#FFFFFF\">5</font> waves. All accumulated rewards <font color=\"#FFFFFF\">+50%</font>."

    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)
    PerkBonus(1)=(baseValue=0, incValue=1, maxValue=-1)
    PerkBonus(2)=(baseValue=0, incValue=2, maxValue=-1)

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_0'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_1'
	UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_2'
	UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_3'
	UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_4'
	UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'

	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Omen_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_Omen"
}
