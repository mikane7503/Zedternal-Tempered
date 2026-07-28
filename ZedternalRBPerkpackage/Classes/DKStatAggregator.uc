//=============================================================================
// DKStatAggregator
//=============================================================================
// Phase 1 of the "Total Stat Increase" UI system.
//
// Probes every owned perk/skill/equipment upgrade by calling the static
// Modify*() functions on each one with sentinel values, capturing the delta
// as that upgrade's contribution. Both passive and non-passive variants are
// probed; the player's current weapon/pawn context is passed so unconditional
// non-passive bonuses (Hydra Penetration, Bulwark HP) and bonuses applicable
// to the held weapon (Berserker damage on Bzk weapons, DeepReserves on
// Cmd/Sharp weapons) are both captured.
//
// All values stored in FStatBonusData are sign-corrected so that "more = better
// for the player" — Damage Resist, Move Speed, Reload Speed, etc. all read
// as positive numbers when the player has bonuses.
//
// Roguelike accumulator values are read directly from DKPRI.CachedRoguelike*
// (no probing — already aggregated server-side and replicated).
//
// Conditional bonuses (weapon/damage-type gated, e.g. Berserker's +5% damage
// on Berserker weapons) are NOT crunched in Phase 1; vanilla perk wrappers
// known to have such bonuses are listed by name at the bottom of the panel.
//
// Rendering uses a non-linear ResScale curve mirroring DKHudWrapper:
//   <=1080p: linear from 720p baseline (1.0x at 720p, 1.5x at 1080p)
//    >1080p: logarithmic dampening (4K -> 2.12x, 5K -> 2.45x)
// All dimensions and font scales are multiplied by ResScale so the panel
// looks proportionally identical on every supported resolution.
//
// USAGE (from DKHudWrapper.DrawHUD):
//   if (bShowStatPanel && Canvas != None && PlayerOwner != None)
//       class'DKStatAggregator'.static.DrawPanel(Canvas, KFPlayerController(PlayerOwner));
//=============================================================================
class DKStatAggregator extends Object
    abstract;

//=============================================================================
// Aggregated stat data — all values sign-corrected so "more is better".
//=============================================================================
struct FStatBonusData
{
    // Survivability
    var int    HealthBonus;          // additive HP (probed via ModifyHealth)
    var int    ArmorBonus;           // additive armor
    var float  DamageResistPct;      // -ModifyDamageTakenPassive (positive = better)
    var float  HealReceivedPct;      // ModifyHealAmountPassive
    var int    WeightLimitBonus;     // additive weight slots

    // Offense
    var float  DamageDealtPct;       // ModifyDamageGivenPassive
    var float  HardAttackPct;        // ModifyHardAttackDamagePassive
    var float  MeleeSpeedPct;        // -ModifyMeleeAttackSpeedPassive
    var float  PenetrationPct;       // ModifyPenetrationPassive

    // Mobility
    var float  MoveSpeedPct;         // ModifySpeedPassive
    var float  SwitchSpeedPct;       // -ModifyWeaponSwitchTimePassive

    // Weapon handling
    var float  ReloadSpeedPct;       // GetReloadRateScalePassive
    var float  MagSizePct;           // ModifyMagSizeAndNumberPassive
    var float  SpareAmmoPct;         // ModifySpareAmmoAmountPassive
    var float  RateOfFirePct;        // ModifyRateOfFirePassive
    var float  RecoilReducPct;       // -ModifyRecoilPassive

    // Crowd Control
    var float  StunPowerPct;
    var float  StumblePowerPct;
    var float  KnockdownPowerPct;
    var float  SnarePowerPct;

    // Counts (footer info)
    var int    PerkCount;
    var int    SkillCount;
    var int    EquipmentCount;
    var int    WeaponUpgCount;

    // Conditional sources (perks with weapon-gated bonuses to flag)
    var array<string> ConditionalSources;
};

// Vanilla perk wrappers that have weapon-gated ModifyDamageGiven overrides.
// Listed by class path so we can match them when scanning owned perks.
var const array<string> KnownConditionalPerks;


//=============================================================================
// PUBLIC ENTRY POINT
//=============================================================================

/** Draw the stats panel on the canvas. Pulls WMPRI/WMGRI from KFPC. */
static simulated function DrawPanel(Canvas C, KFPlayerController KFPC)
{
    local FStatBonusData D;
    local WMPlayerReplicationInfo WMPRI;
    local WMGameReplicationInfo WMGRI;
    local DKPlayerReplicationInfo DKPRI;
    local float RS;
    local float PanelX, PanelY, PanelW, PanelH, CurY;
    local float PadX, PadY, LineH, HeaderH, TitleH, SectionGap, SepH;
    local Color TitleCol, BorderCol, LabelCol, NeutralCol, FooterCol;
    local Color GoodCol, BadCol;
    local Color SurvHeaderCol, OffHeaderCol, MobHeaderCol, WepHeaderCol, CCHeaderCol, RogHeaderCol;
    local Color RogValueCol, CondCol;

    if (C == None || KFPC == None)
        return;

    WMPRI = WMPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
    WMGRI = WMGameReplicationInfo(KFPC.WorldInfo.GRI);
    DKPRI = DKPlayerReplicationInfo(KFPC.PlayerReplicationInfo);

    if (WMPRI == None || WMGRI == None)
        return;

    // ---- ResScale (matches DKHudWrapper curve) ----
    RS = ComputeResScale(C);

    // ---- Aggregate ----
    D = Aggregate(WMPRI, WMGRI, KFPC);

    // ---- Layout (base values, all multiplied by ResScale) ----
    PadX        = 20.0f * RS;
    PadY        = 14.0f * RS;
    TitleH      = 30.0f * RS;
    HeaderH     = 26.0f * RS;
    LineH       = 22.0f * RS;
    SectionGap  = 10.0f * RS;
    SepH        = FMax(1.0f, 1.0f * RS);
    PanelW      = 440.0f * RS;
    PanelH      = MeasurePanelHeight(D, DKPRI, RS);

    PanelX = float(C.SizeX) - PanelW - (30.0f * RS);
    PanelY = (float(C.SizeY) - PanelH) * 0.5f;
    if (PanelY < 30.0f * RS)
        PanelY = 30.0f * RS;

    // ---- Color palette (deliberate, theme-coded sections) ----
    TitleCol      = MakeColor(255, 215, 50,  255);   // gold title
    BorderCol     = MakeColor(200, 170, 50,  220);   // gold border
    LabelCol      = MakeColor(215, 215, 220, 255);   // soft white labels
    NeutralCol    = MakeColor(160, 160, 165, 255);   // grey
    FooterCol     = MakeColor(140, 140, 145, 255);   // dim grey footer

    // Value sign coding
    GoodCol       = MakeColor(130, 240, 140, 255);   // green = bonus
    BadCol        = MakeColor(255, 115, 115, 255);   // red = penalty

    // Section header colors (each thematic)
    SurvHeaderCol = MakeColor(100, 230, 130, 255);   // green - safety
    OffHeaderCol  = MakeColor(255, 140, 90,  255);   // orange-red - aggression
    MobHeaderCol  = MakeColor(110, 200, 255, 255);   // cyan - speed
    WepHeaderCol  = MakeColor(255, 205, 90,  255);   // gold - handling
    CCHeaderCol   = MakeColor(195, 130, 250, 255);   // violet - crowd ctrl
    RogHeaderCol  = MakeColor(225, 110, 220, 255);   // magenta - roguelike

    // Roguelike values keep magenta to distinguish from regular bonuses
    RogValueCol   = MakeColor(235, 150, 230, 255);
    CondCol       = MakeColor(150, 195, 230, 255);   // dim cyan for conditionals

    C.Font = class'KFGameEngine'.static.GetKFCanvasFont();

    // ---- Background + border ----
    DrawPanelBackground(C, PanelX, PanelY, PanelW, PanelH, RS, BorderCol);

    CurY = PanelY + PadY;

    // ---- Title ----
    DrawTextWithShadow(C, "TOTAL STAT INCREASE", PanelX + PadX, CurY, TitleCol, 1.05f * RS);
    CurY += TitleH;

    // Title separator (gold rule)
    C.SetDrawColor(TitleCol.R, TitleCol.G, TitleCol.B, 130);
    C.SetPos(PanelX + PadX, CurY);
    C.DrawRect(PanelW - PadX * 2.0f, SepH);
    CurY += 8.0f * RS;

    // ===== SURVIVABILITY =====
    if (HasSurvivabilityData(D))
    {
        DrawSectionHeader(C, "SURVIVABILITY", PanelX + PadX, CurY, SurvHeaderCol, RS);
        CurY += HeaderH;

        if (D.HealthBonus != 0)
        {
            DrawStatLine(C, "Max Health", FormatInt(D.HealthBonus),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(float(D.HealthBonus), GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.ArmorBonus != 0)
        {
            DrawStatLine(C, "Max Armor", FormatInt(D.ArmorBonus),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(float(D.ArmorBonus), GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.DamageResistPct != 0)
        {
            DrawStatLine(C, "Damage Resist", FormatPct(D.DamageResistPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.DamageResistPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.HealReceivedPct != 0)
        {
            DrawStatLine(C, "Heal Received", FormatPct(D.HealReceivedPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.HealReceivedPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.WeightLimitBonus != 0)
        {
            DrawStatLine(C, "Weight Limit", FormatInt(D.WeightLimitBonus),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(float(D.WeightLimitBonus), GoodCol, BadCol), RS);
            CurY += LineH;
        }

        CurY += SectionGap;
    }

    // ===== OFFENSE =====
    if (HasOffenseData(D))
    {
        DrawSectionHeader(C, "OFFENSE", PanelX + PadX, CurY, OffHeaderCol, RS);
        CurY += HeaderH;

        if (D.DamageDealtPct != 0)
        {
            DrawStatLine(C, "Damage Dealt", FormatPct(D.DamageDealtPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.DamageDealtPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.HardAttackPct != 0)
        {
            DrawStatLine(C, "Heavy Attack", FormatPct(D.HardAttackPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.HardAttackPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.MeleeSpeedPct != 0)
        {
            DrawStatLine(C, "Melee Speed", FormatPct(D.MeleeSpeedPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.MeleeSpeedPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.PenetrationPct != 0)
        {
            DrawStatLine(C, "Penetration", FormatPct(D.PenetrationPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.PenetrationPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }

        CurY += SectionGap;
    }

    // ===== MOBILITY =====
    if (HasMobilityData(D))
    {
        DrawSectionHeader(C, "MOBILITY", PanelX + PadX, CurY, MobHeaderCol, RS);
        CurY += HeaderH;

        if (D.MoveSpeedPct != 0)
        {
            DrawStatLine(C, "Move Speed", FormatPct(D.MoveSpeedPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.MoveSpeedPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.SwitchSpeedPct != 0)
        {
            DrawStatLine(C, "Switch Speed", FormatPct(D.SwitchSpeedPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.SwitchSpeedPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }

        CurY += SectionGap;
    }

    // ===== WEAPON HANDLING =====
    if (HasWeaponHandlingData(D))
    {
        DrawSectionHeader(C, "WEAPON HANDLING", PanelX + PadX, CurY, WepHeaderCol, RS);
        CurY += HeaderH;

        if (D.ReloadSpeedPct != 0)
        {
            DrawStatLine(C, "Reload Speed", FormatPct(D.ReloadSpeedPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.ReloadSpeedPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.MagSizePct != 0)
        {
            DrawStatLine(C, "Mag Size", FormatPct(D.MagSizePct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.MagSizePct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.SpareAmmoPct != 0)
        {
            DrawStatLine(C, "Spare Ammo", FormatPct(D.SpareAmmoPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.SpareAmmoPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.RateOfFirePct != 0)
        {
            DrawStatLine(C, "Rate of Fire", FormatPct(D.RateOfFirePct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.RateOfFirePct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.RecoilReducPct != 0)
        {
            DrawStatLine(C, "Recoil Reduction", FormatPct(D.RecoilReducPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.RecoilReducPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }

        CurY += SectionGap;
    }

    // ===== CROWD CONTROL =====
    if (HasCrowdControlData(D))
    {
        DrawSectionHeader(C, "CROWD CONTROL", PanelX + PadX, CurY, CCHeaderCol, RS);
        CurY += HeaderH;

        if (D.StunPowerPct != 0)
        {
            DrawStatLine(C, "Stun Power", FormatPct(D.StunPowerPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.StunPowerPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.StumblePowerPct != 0)
        {
            DrawStatLine(C, "Stumble Power", FormatPct(D.StumblePowerPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.StumblePowerPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.KnockdownPowerPct != 0)
        {
            DrawStatLine(C, "Knockdown Power", FormatPct(D.KnockdownPowerPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.KnockdownPowerPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }
        if (D.SnarePowerPct != 0)
        {
            DrawStatLine(C, "Snare Power", FormatPct(D.SnarePowerPct),
                PanelX, CurY, PanelW, PadX, LabelCol,
                SignColor(D.SnarePowerPct, GoodCol, BadCol), RS);
            CurY += LineH;
        }

        CurY += SectionGap;
    }

    // ===== ROGUELIKE =====
    if (HasRoguelikeData(DKPRI))
    {
        DrawSectionHeader(C, "ROGUELIKE", PanelX + PadX, CurY, RogHeaderCol, RS);
        CurY += HeaderH;

        if (DKPRI.CachedRoguelikeHealthBonus != 0)
        {
            DrawStatLine(C, "Health", FormatInt(DKPRI.CachedRoguelikeHealthBonus),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeArmorBonus != 0)
        {
            DrawStatLine(C, "Armor", FormatInt(DKPRI.CachedRoguelikeArmorBonus),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeDamageMult != 0)
        {
            DrawStatLine(C, "Damage", FormatPct(DKPRI.CachedRoguelikeDamageMult),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeDamageResist != 0)
        {
            DrawStatLine(C, "Damage Resist", FormatPct(DKPRI.CachedRoguelikeDamageResist),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeSpeedMult != 0)
        {
            DrawStatLine(C, "Move Speed", FormatPct(DKPRI.CachedRoguelikeSpeedMult),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeReloadMult != 0)
        {
            DrawStatLine(C, "Reload Speed", FormatPct(DKPRI.CachedRoguelikeReloadMult),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeAmmoMult != 0)
        {
            DrawStatLine(C, "Spare Ammo", FormatPct(DKPRI.CachedRoguelikeAmmoMult),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeLargeZedDamage != 0)
        {
            DrawStatLine(C, "vs. Large Zeds", FormatPct(DKPRI.CachedRoguelikeLargeZedDamage),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeLuck != 0)
        {
            DrawStatLine(C, "Luck", FormatPct(DKPRI.CachedRoguelikeLuck),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }
        if (DKPRI.CachedRoguelikeWaveStartDosh != 0)
        {
            DrawStatLine(C, "Wave Start Dosh", FormatInt(DKPRI.CachedRoguelikeWaveStartDosh),
                PanelX, CurY, PanelW, PadX, LabelCol, RogValueCol, RS);
            CurY += LineH;
        }

        CurY += SectionGap;
    }

    // ===== CONDITIONAL =====
    if (D.ConditionalSources.length > 0)
    {
        DrawSectionHeader(C, "CONDITIONAL (perk-gated bonuses)", PanelX + PadX, CurY, NeutralCol, RS);
        CurY += HeaderH;

        DrawConditionalList(C, D.ConditionalSources, PanelX + PadX + (12.0f * RS), CurY, CondCol, RS);
        CurY += MeasureConditionalHeight(D.ConditionalSources, RS);

        CurY += SectionGap;
    }

    // ===== FOOTER =====
    DrawTextWithShadow(C,
        "Sources:" @ D.PerkCount $ "p" @ "/" @ D.SkillCount $ "s" @ "/" @ D.EquipmentCount $ "e" @ "/" @ D.WeaponUpgCount $ "w   (passive only)",
        PanelX + PadX, CurY, FooterCol, 0.72f * RS);
}


//=============================================================================
// AGGREGATION — probe every owned upgrade
//=============================================================================
static function FStatBonusData Aggregate(WMPlayerReplicationInfo WMPRI, WMGameReplicationInfo WMGRI, KFPlayerController KFPC)
{
    local FStatBonusData D;
    local int i, idx, lvl;
    local class<WMUpgrade> UpgClass;
    local string UpgPath;

    if (WMPRI == None || WMGRI == None)
        return D;

    // ---- Perk upgrades ----
    for (i = 0; i < WMPRI.Purchase_PerkUpgrade.length; ++i)
    {
        idx = WMPRI.Purchase_PerkUpgrade[i];
        if (idx < 0 || idx >= WMGRI.PerkUpgradesList.length)
            continue;

        UpgClass = WMGRI.PerkUpgradesList[idx].PerkUpgrade;
        lvl = WMPRI.bPerkUpgrade[idx].level;
        if (UpgClass != None && lvl > 0)
        {
            ProbeUpgrade(UpgClass, lvl, KFPC, D);

            // Flag known-conditional perk wrappers (UpgradeName is set in
            // each subclass's defaultproperties as the full "Package.Class" path).
            UpgPath = UpgClass.default.UpgradeName;
            if (default.KnownConditionalPerks.Find(UpgPath) != INDEX_NONE)
            {
                D.ConditionalSources.AddItem(GetSimpleName(UpgPath) @ "(Lvl" @ lvl $ ")");
            }

            D.PerkCount += 1;
        }
    }

    // ---- Skill upgrades ----
    for (i = 0; i < WMPRI.Purchase_SkillUpgrade.length; ++i)
    {
        idx = WMPRI.Purchase_SkillUpgrade[i];
        if (idx < 0 || idx >= WMGRI.SkillUpgradesList.length)
            continue;

        UpgClass = WMGRI.SkillUpgradesList[idx].SkillUpgrade;
        lvl = WMPRI.GetSkillUpgrade(idx);
        if (UpgClass != None && lvl > 0)
        {
            ProbeUpgrade(UpgClass, lvl, KFPC, D);
            D.SkillCount += 1;
        }
    }

    // ---- Equipment upgrades ----
    for (i = 0; i < WMPRI.Purchase_EquipmentUpgrade.length; ++i)
    {
        idx = WMPRI.Purchase_EquipmentUpgrade[i];
        if (idx < 0 || idx >= WMGRI.EquipmentUpgradesList.length)
            continue;

        UpgClass = WMGRI.EquipmentUpgradesList[idx].EquipmentUpgrade;
        lvl = WMPRI.bEquipmentUpgrade[idx];
        if (UpgClass != None && lvl > 0)
        {
            ProbeUpgrade(UpgClass, lvl, KFPC, D);
            D.EquipmentCount += 1;
        }
    }

    // Weapon upgrades require KFWeapon context for every probe — Phase 2 territory.
    // For Phase 1 we just report the count.
    D.WeaponUpgCount = WMPRI.Purchase_WeaponUpgrade.length;

    return D;
}

/** Probe a single upgrade class and add its contributions to D.
 *
 *  Calls BOTH passive and non-passive Modify*() variants. Passive variants
 *  are unconditional by design. Non-passive variants may gate on weapon /
 *  damage-type / pawn context; we pass the player's current weapon and pawn
 *  so unconditional non-passive bonuses (Hydra Penetration, Bulwark HP) and
 *  bonuses applicable to the held weapon (Berserker damage on Bzk weapons,
 *  DeepReserves on Cmd/Sharp weapons) are both captured.
 *
 *  Limitations:
 *    - Damage-type-gated bonuses miss (Resilience requires DT)
 *    - Target-zed-gated bonuses miss (Hydra fury damage needs MyKFPM)
 *    - Event-based skills miss (ArmoredUp armor-on-kill)
 *    - Zed-time-only buffs miss (Marathon)
 *
 *  Side-effect note: some non-passive Modify* implementations have minor
 *  side effects (spawn helpers, ClientMessage on fury mode). Probing every
 *  frame may trigger these. Acceptable for Phase 1; cache later if needed.
 */
static function ProbeUpgrade(class<WMUpgrade> Upg, int lvl, KFPlayerController KFPC, out FStatBonusData D)
{
    local int   iH, iArmor, iWeight, iVal;
    local float fVal, fIn;
    local KFWeapon KFW;
    local KFPawn  KFP;
    local class<KFDamageType> NoDT;
    local STraderItem EmptyTraderItem;

    if (Upg == None || lvl <= 0)
        return;

    // Explicit None init to silence "used before assigned" warning.
    // Used as a placeholder for the required class<KFDamageType> param in
    // ModifyPenetration() and as optional skip in ModifyDamageTaken().
    NoDT = None;

    // Extract context. May be None on death/spectator — functions that gate on
    // null context will simply early-return, which is the correct behavior.
    if (KFPC != None)
    {
        KFP = KFPawn(KFPC.Pawn);
        if (KFP != None)
            KFW = KFWeapon(KFP.Weapon);
    }

    // ===== SURVIVABILITY =====

    // Max HP — ModifyHealth (no context). Probe with In=100, Default=100.
    iH = 100;
    Upg.static.ModifyHealth(iH, 100, lvl);
    D.HealthBonus += (iH - 100);

    // Max Armor — ModifyArmor (no context).
    iArmor = 100;
    Upg.static.ModifyArmor(iArmor, 100, lvl);
    D.ArmorBonus += (iArmor - 100);

    // Damage Resist — passive + non-passive (with KFP context, no DT/instigator).
    // Passive: factor accumulator; positive = MORE damage taken (bad), negate.
    fVal = 0.0f;
    Upg.static.ModifyDamageTakenPassive(fVal, lvl);
    D.DamageResistPct -= fVal;
    // Non-passive: probe with In=100, Default=100 absolute; reduced result = resist.
    iVal = 100;
    Upg.static.ModifyDamageTaken(iVal, 100, lvl, KFP, NoDT, , KFW);
    if (iVal != 100)
        D.DamageResistPct += (100.0f - float(iVal)) / 100.0f;

    // Heal Received — passive (factor) + non-passive (absolute on healing amount).
    fVal = 0.0f;
    Upg.static.ModifyHealAmountPassive(fVal, lvl);
    D.HealReceivedPct += fVal;
    fIn = 100.0f;
    Upg.static.ModifyHealAmount(fIn, 100.0f, lvl);
    if (fIn != 100.0f)
        D.HealReceivedPct += (fIn - 100.0f) / 100.0f;

    // Weight Limit — ApplyWeightLimits (no context). KF2 default is 15.
    iWeight = 15;
    Upg.static.ApplyWeightLimits(iWeight, 15, lvl);
    D.WeightLimitBonus += (iWeight - 15);

    // ===== OFFENSE =====

    // Damage Dealt — passive + non-passive (with weapon/PC context).
    fVal = 0.0f;
    Upg.static.ModifyDamageGivenPassive(fVal, lvl);
    D.DamageDealtPct += fVal;
    iVal = 100;
    // Args: InDamage, DefaultDamage, lvl, DamageCauser=None, MyKFPM=None,
    //       DamageInstigator=KFPC, DamageType=None, HitZoneIdx=0, MyKFW=KFW
    Upg.static.ModifyDamageGiven(iVal, 100, lvl, , , KFPC, , , KFW);
    if (iVal != 100)
        D.DamageDealtPct += (float(iVal) - 100.0f) / 100.0f;

    // Hard Attack — passive + non-passive (needs OwnerPawn).
    fVal = 0.0f;
    Upg.static.ModifyHardAttackDamagePassive(fVal, lvl);
    D.HardAttackPct += fVal;
    iVal = 100;
    Upg.static.ModifyHardAttackDamage(iVal, 100, lvl, KFP);
    if (iVal != 100)
        D.HardAttackPct += (float(iVal) - 100.0f) / 100.0f;

    // Penetration — passive + non-passive. Param 4 (DamageType) is required
    // by signature; pass None placeholder so unconditional bonuses still capture.
    fVal = 0.0f;
    Upg.static.ModifyPenetrationPassive(fVal, lvl);
    D.PenetrationPct += fVal;
    fIn = 100.0f;
    Upg.static.ModifyPenetration(fIn, 100.0f, lvl, NoDT, KFP);
    if (fIn != 100.0f)
        D.PenetrationPct += (fIn - 100.0f) / 100.0f;

    // Melee Speed — passive (harmonic) + non-passive (with KFW). Time-style:
    // lower result = faster. bonus = 1.0 - result works for both additive and harmonic.
    fVal = 1.0f;
    Upg.static.ModifyMeleeAttackSpeedPassive(fVal, lvl);
    if (fVal > 0.0f && fVal != 1.0f)
        D.MeleeSpeedPct += (1.0f - fVal);
    fIn = 1.0f;
    Upg.static.ModifyMeleeAttackSpeed(fIn, 1.0f, lvl, KFW);
    if (fIn > 0.0f && fIn != 1.0f)
        D.MeleeSpeedPct += (1.0f - fIn);

    // ===== MOBILITY =====

    // Move Speed — passive (additive) + non-passive (with KFP).
    fVal = 0.0f;
    Upg.static.ModifySpeedPassive(fVal, lvl);
    D.MoveSpeedPct += fVal;
    fIn = 100.0f;
    Upg.static.ModifySpeed(fIn, 100.0f, lvl, KFP);
    if (fIn != 100.0f)
        D.MoveSpeedPct += (fIn - 100.0f) / 100.0f;

    // Switch Speed — passive (harmonic) + non-passive. Time-style: lower = faster.
    fVal = 1.0f;
    Upg.static.ModifyWeaponSwitchTimePassive(fVal, lvl);
    if (fVal > 0.0f && fVal != 1.0f)
        D.SwitchSpeedPct += (1.0f - fVal);
    fIn = 1.0f;
    Upg.static.ModifyWeaponSwitchTime(fIn, 1.0f, lvl, KFW);
    if (fIn > 0.0f && fIn != 1.0f)
        D.SwitchSpeedPct += (1.0f - fIn);

    // ===== WEAPON HANDLING =====

    // Reload Speed — passive (harmonic) + non-passive (with KFW, KFP).
    fVal = 1.0f;
    Upg.static.GetReloadRateScalePassive(fVal, lvl);
    if (fVal > 0.0f && fVal != 1.0f)
        D.ReloadSpeedPct += (1.0f - fVal);
    fIn = 1.0f;
    Upg.static.GetReloadRateScale(fIn, lvl, KFW, KFP);
    if (fIn > 0.0f && fIn != 1.0f)
        D.ReloadSpeedPct += (1.0f - fIn);

    // Mag Size — passive (factor) + non-passive (additive on Default with KFW).
    fVal = 0.0f;
    Upg.static.ModifyMagSizeAndNumberPassive(fVal, lvl);
    D.MagSizePct += fVal;
    iVal = 100;
    Upg.static.ModifyMagSizeAndNumber(iVal, 100, lvl, KFW);
    if (iVal != 100)
        D.MagSizePct += (float(iVal) - 100.0f) / 100.0f;

    // Spare Ammo — passive (factor) + non-passive (with KFW, default TraderItem).
    fVal = 0.0f;
    Upg.static.ModifySpareAmmoAmountPassive(fVal, lvl);
    D.SpareAmmoPct += fVal;
    iVal = 100;
    Upg.static.ModifySpareAmmoAmount(iVal, 100, lvl, KFW, EmptyTraderItem, false);
    if (iVal != 100)
        D.SpareAmmoPct += (float(iVal) - 100.0f) / 100.0f;

    // Rate of Fire — passive (harmonic) + non-passive (with KFW).
    fVal = 1.0f;
    Upg.static.ModifyRateOfFirePassive(fVal, lvl);
    if (fVal > 0.0f && fVal != 1.0f)
        D.RateOfFirePct += (1.0f - fVal);
    fIn = 1.0f;
    Upg.static.ModifyRateOfFire(fIn, 1.0f, lvl, KFW);
    if (fIn > 0.0f && fIn != 1.0f)
        D.RateOfFirePct += (1.0f - fIn);

    // Recoil — passive (multiplicative) + non-passive (with KFW). Lower = better.
    fVal = 1.0f;
    Upg.static.ModifyRecoilPassive(fVal, lvl);
    if (fVal != 1.0f)
        D.RecoilReducPct += (1.0f - fVal);
    fIn = 1.0f;
    Upg.static.ModifyRecoil(fIn, 1.0f, lvl, KFW);
    if (fIn != 1.0f)
        D.RecoilReducPct += (1.0f - fIn);

    // ===== CROWD CONTROL =====

    // Stun — passive + non-passive (no required context, optional DT/HitZone).
    fVal = 0.0f;
    Upg.static.ModifyStunPowerPassive(fVal, lvl);
    D.StunPowerPct += fVal;
    fIn = 100.0f;
    Upg.static.ModifyStunPower(fIn, 100.0f, lvl);
    if (fIn != 100.0f)
        D.StunPowerPct += (fIn - 100.0f) / 100.0f;

    // Stumble — passive + non-passive.
    fVal = 0.0f;
    Upg.static.ModifyStumblePowerPassive(fVal, lvl);
    D.StumblePowerPct += fVal;
    fIn = 100.0f;
    Upg.static.ModifyStumblePower(fIn, 100.0f, lvl);
    if (fIn != 100.0f)
        D.StumblePowerPct += (fIn - 100.0f) / 100.0f;

    // Knockdown — passive + non-passive (needs OwnerPawn).
    fVal = 0.0f;
    Upg.static.ModifyKnockdownPowerPassive(fVal, lvl);
    D.KnockdownPowerPct += fVal;
    fIn = 100.0f;
    Upg.static.ModifyKnockdownPower(fIn, 100.0f, lvl, KFP);
    if (fIn != 100.0f)
        D.KnockdownPowerPct += (fIn - 100.0f) / 100.0f;

    // Snare — passive + non-passive.
    fVal = 0.0f;
    Upg.static.ModifySnarePowerPassive(fVal, lvl);
    D.SnarePowerPct += fVal;
    fIn = 100.0f;
    Upg.static.ModifySnarePower(fIn, 100.0f, lvl);
    if (fIn != 100.0f)
        D.SnarePowerPct += (fIn - 100.0f) / 100.0f;
}

//=============================================================================
// SECTION DATA CHECKS — skip empty sections to keep panel compact
//=============================================================================
static function bool HasSurvivabilityData(FStatBonusData D)
{
    return D.HealthBonus != 0 || D.ArmorBonus != 0 || D.DamageResistPct != 0
        || D.HealReceivedPct != 0 || D.WeightLimitBonus != 0;
}

static function bool HasOffenseData(FStatBonusData D)
{
    return D.DamageDealtPct != 0 || D.HardAttackPct != 0
        || D.MeleeSpeedPct != 0 || D.PenetrationPct != 0;
}

static function bool HasMobilityData(FStatBonusData D)
{
    return D.MoveSpeedPct != 0 || D.SwitchSpeedPct != 0;
}

static function bool HasWeaponHandlingData(FStatBonusData D)
{
    return D.ReloadSpeedPct != 0 || D.MagSizePct != 0 || D.SpareAmmoPct != 0
        || D.RateOfFirePct != 0 || D.RecoilReducPct != 0;
}

static function bool HasCrowdControlData(FStatBonusData D)
{
    return D.StunPowerPct != 0 || D.StumblePowerPct != 0
        || D.KnockdownPowerPct != 0 || D.SnarePowerPct != 0;
}

static function bool HasRoguelikeData(DKPlayerReplicationInfo DKPRI)
{
    if (DKPRI == None)
        return false;

    return DKPRI.CachedRoguelikeHealthBonus    != 0
        || DKPRI.CachedRoguelikeArmorBonus     != 0
        || DKPRI.CachedRoguelikeDamageMult     != 0
        || DKPRI.CachedRoguelikeDamageResist   != 0
        || DKPRI.CachedRoguelikeSpeedMult      != 0
        || DKPRI.CachedRoguelikeReloadMult     != 0
        || DKPRI.CachedRoguelikeAmmoMult       != 0
        || DKPRI.CachedRoguelikeLargeZedDamage != 0
        || DKPRI.CachedRoguelikeLuck           != 0
        || DKPRI.CachedRoguelikeWaveStartDosh  != 0;
}


//=============================================================================
// MEASUREMENT — pre-compute panel height for centering
//=============================================================================
static function float MeasurePanelHeight(FStatBonusData D, DKPlayerReplicationInfo DKPRI, float RS)
{
    local float H;
    local float PadY, TitleH, HeaderH, LineH, SectionGap, SepGap;

    PadY        = 14.0f * RS;
    TitleH      = 30.0f * RS;
    HeaderH     = 26.0f * RS;
    LineH       = 22.0f * RS;
    SectionGap  = 10.0f * RS;
    SepGap      = 8.0f * RS;  // gap below title separator

    // Title + separator + footer baseline (footer = 18*RS)
    H = PadY + TitleH + SepGap + (18.0f * RS) + PadY;

    if (HasSurvivabilityData(D))
    {
        H += HeaderH + SectionGap;
        if (D.HealthBonus      != 0) H += LineH;
        if (D.ArmorBonus       != 0) H += LineH;
        if (D.DamageResistPct  != 0) H += LineH;
        if (D.HealReceivedPct  != 0) H += LineH;
        if (D.WeightLimitBonus != 0) H += LineH;
    }
    if (HasOffenseData(D))
    {
        H += HeaderH + SectionGap;
        if (D.DamageDealtPct != 0) H += LineH;
        if (D.HardAttackPct  != 0) H += LineH;
        if (D.MeleeSpeedPct  != 0) H += LineH;
        if (D.PenetrationPct != 0) H += LineH;
    }
    if (HasMobilityData(D))
    {
        H += HeaderH + SectionGap;
        if (D.MoveSpeedPct   != 0) H += LineH;
        if (D.SwitchSpeedPct != 0) H += LineH;
    }
    if (HasWeaponHandlingData(D))
    {
        H += HeaderH + SectionGap;
        if (D.ReloadSpeedPct != 0) H += LineH;
        if (D.MagSizePct     != 0) H += LineH;
        if (D.SpareAmmoPct   != 0) H += LineH;
        if (D.RateOfFirePct  != 0) H += LineH;
        if (D.RecoilReducPct != 0) H += LineH;
    }
    if (HasCrowdControlData(D))
    {
        H += HeaderH + SectionGap;
        if (D.StunPowerPct      != 0) H += LineH;
        if (D.StumblePowerPct   != 0) H += LineH;
        if (D.KnockdownPowerPct != 0) H += LineH;
        if (D.SnarePowerPct     != 0) H += LineH;
    }
    if (HasRoguelikeData(DKPRI))
    {
        H += HeaderH + SectionGap;
        if (DKPRI.CachedRoguelikeHealthBonus    != 0) H += LineH;
        if (DKPRI.CachedRoguelikeArmorBonus     != 0) H += LineH;
        if (DKPRI.CachedRoguelikeDamageMult     != 0) H += LineH;
        if (DKPRI.CachedRoguelikeDamageResist   != 0) H += LineH;
        if (DKPRI.CachedRoguelikeSpeedMult      != 0) H += LineH;
        if (DKPRI.CachedRoguelikeReloadMult     != 0) H += LineH;
        if (DKPRI.CachedRoguelikeAmmoMult       != 0) H += LineH;
        if (DKPRI.CachedRoguelikeLargeZedDamage != 0) H += LineH;
        if (DKPRI.CachedRoguelikeLuck           != 0) H += LineH;
        if (DKPRI.CachedRoguelikeWaveStartDosh  != 0) H += LineH;
    }
    if (D.ConditionalSources.length > 0)
    {
        H += HeaderH + SectionGap;
        H += MeasureConditionalHeight(D.ConditionalSources, RS);
    }

    // Floor at minimum height
    if (H < 120.0f * RS)
        H = 120.0f * RS;

    return H;
}

static function float MeasureConditionalHeight(array<string> Sources, float RS)
{
    return float(Sources.length) * (18.0f * RS);
}


//=============================================================================
// DRAWING HELPERS
//=============================================================================
static function DrawSectionHeader(Canvas C, string Text, float X, float Y, Color Col, float RS)
{
    local float TextW, TextH;
    local float UnderlineY;

    DrawTextWithShadow(C, Text, X, Y, Col, 0.95f * RS);

    // Draw a subtle underline beneath the section header for visual separation
    C.TextSize(Text, TextW, TextH, 0.95f * RS, 0.95f * RS);
    UnderlineY = Y + TextH + (2.0f * RS);
    C.SetDrawColor(Col.R, Col.G, Col.B, 90);
    C.SetPos(X, UnderlineY);
    C.DrawRect(TextW, FMax(1.0f, 1.0f * RS));
}

static function DrawStatLine(Canvas C, string Label, string Value,
    float PanelX, float Y, float PanelW, float PadX,
    Color LabelCol, Color ValueCol, float RS)
{
    local float TextW, TextH, ValueX;
    local float Indent;
    local float LineScale;

    LineScale = 0.85f * RS;
    Indent = 14.0f * RS;

    // Label (left-aligned, indented from section header)
    DrawTextWithShadow(C, Label, PanelX + PadX + Indent, Y, LabelCol, LineScale);

    // Value (right-aligned with safe right margin)
    C.TextSize(Value, TextW, TextH, LineScale, LineScale);
    ValueX = PanelX + PanelW - PadX - TextW;
    DrawTextWithShadow(C, Value, ValueX, Y, ValueCol, LineScale);
}

static function DrawConditionalList(Canvas C, array<string> Sources,
    float X, float Y, Color Col, float RS)
{
    local int i;
    local float CurY;
    local float Step;

    Step = 18.0f * RS;
    CurY = Y;
    for (i = 0; i < Sources.length; ++i)
    {
        DrawTextWithShadow(C, "- " $ Sources[i], X, CurY, Col, 0.78f * RS);
        CurY += Step;
    }
}

static function DrawPanelBackground(Canvas C, float X, float Y, float W, float H, float RS, Color BorderCol)
{
    local float Th;

    Th = FMax(2.0f, 2.0f * RS);

    // Dark navy panel with high opacity for readability
    C.SetDrawColor(12, 16, 24, 230);
    C.SetPos(X, Y);
    C.DrawRect(W, H);

    // Subtle inner highlight (1px row at top for shine effect)
    C.SetDrawColor(40, 50, 70, 120);
    C.SetPos(X, Y);
    C.DrawRect(W, FMax(1.0f, 1.0f * RS));

    // Gold border (4 edges, scaled thickness)
    C.SetDrawColor(BorderCol.R, BorderCol.G, BorderCol.B, BorderCol.A);
    C.SetPos(X, Y);                                C.DrawRect(W, Th);
    C.SetPos(X, Y + H - Th);                       C.DrawRect(W, Th);
    C.SetPos(X, Y);                                C.DrawRect(Th, H);
    C.SetPos(X + W - Th, Y);                       C.DrawRect(Th, H);
}

static function DrawTextWithShadow(Canvas C, string Text, float X, float Y, Color Col, float Scale)
{
    // Drop shadow at fixed 1px offset (regardless of ResScale, for crispness)
    C.SetDrawColor(0, 0, 0, 200);
    C.SetPos(X + 1, Y + 1);
    C.DrawText(Text, true, Scale, Scale);

    // Foreground
    C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
    C.SetPos(X, Y);
    C.DrawText(Text, true, Scale, Scale);
}


//=============================================================================
// COLOR HELPERS
//=============================================================================

/** Compute ResScale matching DKHudWrapper.ComputeResScale curve.
 *  <=1080p: linear from 720p (1.0x at 720p, 1.5x at 1080p)
 *   >1080p: logarithmic (1.5 * sqrt(H / 1080)) — 4K -> 2.12x */
static function float ComputeResScale(Canvas C)
{
    local float H, Scale;

    if (C == None || C.SizeY <= 0)
        return 1.0f;

    H = float(C.SizeY);

    if (H <= 1080.0f)
        Scale = H / 720.0f;
    else
        Scale = 1.5f * Sqrt(H / 1080.0f);

    // Clamp to sane range
    if (Scale < 0.75f) Scale = 0.75f;
    if (Scale > 4.0f)  Scale = 4.0f;

    return Scale;
}

/** Pick green (positive) or red (negative) by sign of V. */
static function Color SignColor(float V, Color GoodCol, Color BadCol)
{
    if (V >= 0.0f)
        return GoodCol;
    return BadCol;
}


//=============================================================================
// FORMATTERS
//=============================================================================
static function string FormatPct(float V)
{
    local int Pct;
    Pct = Round(V * 100.0f);

    if (Pct >= 0)
        return "+" $ string(Pct) $ "%";
    else
        return string(Pct) $ "%";
}

static function string FormatInt(int V)
{
    if (V >= 0)
        return "+" $ string(V);
    else
        return string(V);
}

/** Strip the "Package.Class_" prefix and return a friendly perk name.
 *  Input:  "ZedternalReborn.WMUpgrade_Perk_Berserker"
 *  Output: "Berserker" */
static function string GetSimpleName(string FullPath)
{
    local int LastUnderscore;
    local string AfterDot, Result;
    local array<string> DotParts;

    ParseStringIntoArray(FullPath, DotParts, ".", true);
    if (DotParts.length >= 2)
        AfterDot = DotParts[DotParts.length - 1];
    else
        AfterDot = FullPath;

    LastUnderscore = InStr(AfterDot, "_", true);
    if (LastUnderscore > 0)
        Result = Mid(AfterDot, LastUnderscore + 1);
    else
        Result = AfterDot;

    return Result;
}


//=============================================================================
// DEFAULT PROPERTIES
//=============================================================================
defaultproperties
{
    // Vanilla perk wrappers known to have weapon-gated ModifyDamageGiven
    // overrides. These get flagged in the "Conditional" section of the panel
    // so players know they have additional bonuses on their respective weapons.
    KnownConditionalPerks(0)="ZedternalReborn.WMUpgrade_Perk_Berserker"
    KnownConditionalPerks(1)="ZedternalReborn.WMUpgrade_Perk_Commando"
    KnownConditionalPerks(2)="ZedternalReborn.WMUpgrade_Perk_Demolitionist"
    KnownConditionalPerks(3)="ZedternalReborn.WMUpgrade_Perk_FieldMedic"
    KnownConditionalPerks(4)="ZedternalReborn.WMUpgrade_Perk_Firebug"
    KnownConditionalPerks(5)="ZedternalReborn.WMUpgrade_Perk_Gunslinger"
    KnownConditionalPerks(6)="ZedternalReborn.WMUpgrade_Perk_Sharpshooter"
    KnownConditionalPerks(7)="ZedternalReborn.WMUpgrade_Perk_Support"
    KnownConditionalPerks(8)="ZedternalReborn.WMUpgrade_Perk_Survivalist"
    KnownConditionalPerks(9)="ZedternalReborn.WMUpgrade_Perk_SWAT"

    Name="Default__DKStatAggregator"
}
