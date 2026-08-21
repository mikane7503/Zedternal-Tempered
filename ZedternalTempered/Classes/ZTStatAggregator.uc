//=============================================================================
// ZTStatAggregator
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
// Rendering uses a non-linear ResScale curve mirroring ZTHudWrapper:
//   <=1080p: linear from 720p baseline (1.0x at 720p, 1.5x at 1080p)
//    >1080p: logarithmic dampening (4K -> 2.12x, 5K -> 2.45x)
// All dimensions and font scales are multiplied by ResScale so the panel
// looks proportionally identical on every supported resolution.
//
// USAGE (from ZTHudWrapper.DrawHUD):
//   if (bShowStatPanel && Canvas != None && PlayerOwner != None)
//       class'ZTStatAggregator'.static.DrawPanel(Canvas, KFPlayerController(PlayerOwner));
//=============================================================================
class ZTStatAggregator extends Object abstract;

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
    // Damage is deliberately split for the compact HUD. DamageDealtPct is
    // truly universal (it still applies with no weapon context); the other
    // two fields are the extra bonus unlocked by the weapon currently held.
    var float  DamageDealtPct;       // universal damage, applies to any attack
    var float  MeleeDamagePct;       // held melee weapon-only damage
    var float  RangedDamagePct;      // held ranged weapon-only damage
    var float  HeadshotDamagePct;    // additional damage when the hit zone is the head
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

static function AddCompactPct(out array<string> Items, string Label, float Value)
{
    local int Pct;
    Pct = Round(Value * 100.0f);
    if (Pct > 0) Items.AddItem(Label $ ": +" $ string(Pct) $ "%");
    else if (Pct < 0) Items.AddItem(Label $ ": " $ string(Pct) $ "%");
}

static function AddCompactInt(out array<string> Items, string Label, int Value)
{
    if (Value > 0) Items.AddItem(Label $ ": +" $ string(Value));
    else if (Value < 0) Items.AddItem(Label $ ": " $ string(Value));
}

/** Build no more than two compact HUD lines. Called by the HUD on a timer. */
static simulated function BuildCompactSummary(KFPlayerController KFPC, out array<string> Lines)
{
    local FStatBonusData D;
    local WMPlayerReplicationInfo WMPRI;
    local WMGameReplicationInfo WMGRI;
    local array<string> Items;
    local int i, LineIndex;

    Lines.Length = 0;
    if (KFPC == None) return;
    WMPRI = WMPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
    WMGRI = WMGameReplicationInfo(KFPC.WorldInfo.GRI);
    if (WMPRI == None || WMGRI == None) return;

    D = Aggregate(WMPRI, WMGRI, KFPC);
    if (ZTPlayerReplicationInfo(WMPRI) != None)
    {
        D.DamageDealtPct += ZTPlayerReplicationInfo(WMPRI).CachedRoguelikeDamageMult;
        D.DamageResistPct += ZTPlayerReplicationInfo(WMPRI).CachedRoguelikeDamageResist;
        D.MoveSpeedPct += ZTPlayerReplicationInfo(WMPRI).CachedRoguelikeSpeedMult;
        D.ReloadSpeedPct += ZTPlayerReplicationInfo(WMPRI).CachedRoguelikeReloadMult;
        D.SpareAmmoPct += ZTPlayerReplicationInfo(WMPRI).CachedRoguelikeAmmoMult;
        D.HealthBonus += ZTPlayerReplicationInfo(WMPRI).CachedRoguelikeHealthBonus;
        D.ArmorBonus += ZTPlayerReplicationInfo(WMPRI).CachedRoguelikeArmorBonus;
    }

    if (KFPC != None && ZTHudWrapper(KFPC.myHUD) != None)
    {
        if (ZTHudWrapper(KFPC.myHUD).PredatorDisplay.bIsActive)
        {
            D.DamageDealtPct += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.AccAllDamage;
            D.DamageResistPct += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.AccDamageResist;
            D.MoveSpeedPct += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.AccSpeed;
            D.ReloadSpeedPct += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.AccReload;
            D.SpareAmmoPct += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.AccSpareAmmo;
            D.MagSizePct += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.AccMagSize;
            D.HeadshotDamagePct += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.AccHeadshotDamage;
            D.HealthBonus += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.StackBonusHP;
            D.ArmorBonus += ZTHudWrapper(KFPC.myHUD).PredatorDisplay.StackBonusArmor;
        }

        if (ZTHudWrapper(KFPC.myHUD).GambitDisplay.bIsActive)
        {
            D.DamageDealtPct += ZTHudWrapper(KFPC.myHUD).GambitDisplay.AccDamage;
            D.MoveSpeedPct += ZTHudWrapper(KFPC.myHUD).GambitDisplay.AccSpeed;
        }
    }

    // Event-driven buffs are not visible to the static Modify* probes above.
    // Read their replicated runtime state here, after the base aggregation.
    // This is deliberately a tiny owned-skill scan, performed only with the
    // existing 0.25s HUD refresh, so it does not add combat-path overhead.
    ApplyLiveConditionalEffects(WMPRI, WMGRI, KFPC, D);

    AddCompactPct(Items, "RES", D.DamageResistPct);
    // Runtime HUD strings must remain ASCII. UnrealScript literals do not use
    // the KOR localization code page, so Korean text here is rendered garbled
    // in the KF2 Canvas path. DMG is the universal portion; MELEE/RANGED is
    // only the extra amount enabled by the weapon currently being held.
    AddCompactPct(Items, "DMG", D.DamageDealtPct);
    AddCompactPct(Items, "MELEE", D.MeleeDamagePct);
    AddCompactPct(Items, "RANGED", D.RangedDamagePct);
    AddCompactPct(Items, "HEAVY", D.HardAttackPct);
    AddCompactPct(Items, "MSPD", D.MeleeSpeedPct);
    AddCompactPct(Items, "HEAD", D.HeadshotDamagePct);
    AddCompactPct(Items, "MOVE", D.MoveSpeedPct);
    AddCompactPct(Items, "RECOIL", D.RecoilReducPct);
    AddCompactPct(Items, "ROF", D.RateOfFirePct);
    AddCompactPct(Items, "PEN", D.PenetrationPct);

    for (i = 0; i < Items.Length; ++i)
    {
        LineIndex = i / 6;
        while (Lines.Length <= LineIndex) Lines.AddItem("");
        if (Lines[LineIndex] != "") Lines[LineIndex] $= "  |  ";
        Lines[LineIndex] $= Items[i];
    }
}

/** Add bonuses that exist only while a replicated helper is active.
 *
 * Parry is the first supported case: a successful parry enables
 * WMUpgrade_Skill_Parry_Helper.bOn for 10 seconds. The ordinary aggregate
 * probe has no way to know that runtime state, so it correctly reports only
 * permanent bonuses unless this is applied separately.
 */
static simulated function ApplyLiveConditionalEffects(WMPlayerReplicationInfo WMPRI,
    WMGameReplicationInfo WMGRI, KFPlayerController KFPC, out FStatBonusData D)
{
    local int i, idx, lvl;
    local class<WMUpgrade> UpgClass;
    local KFPawn OwnerPawn;
    local WMUpgrade_Skill_Parry_Helper ParryHelper;

    if (WMPRI == None || WMGRI == None || KFPC == None)
        return;

    OwnerPawn = KFPawn(KFPC.Pawn);
    if (OwnerPawn == None)
        return;

    // Tempered Parry drives the HUD from the same client callback that starts
    // its effect. Keep actor lookup as a fallback for legacy saves.
    if (ZTHudWrapper(KFPC.myHUD) == None || !ZTHudWrapper(KFPC.myHUD).IsParryStatBuffActive())
    {
        foreach KFPC.AllActors(class'WMUpgrade_Skill_Parry_Helper', ParryHelper)
        {
            if (ParryHelper.Owner == OwnerPawn)
                break;
            ParryHelper = None;
        }
        if (ParryHelper == None || !ParryHelper.bOn)
            return;
    }

    for (i = 0; i < WMPRI.Purchase_SkillUpgrade.length; ++i)
    {
        idx = WMPRI.Purchase_SkillUpgrade[i];
        if (idx < 0 || idx >= WMGRI.SkillUpgradesList.length)
            continue;

        UpgClass = WMGRI.SkillUpgradesList[idx].SkillUpgrade;
        lvl = WMPRI.GetSkillUpgrade(idx);
        if (lvl <= 0)
            return;

        // Tempered can contain the config-wrapper class or the legacy class;
        // display the active bonus from the same defaults that power combat.
        if (UpgClass == class'ZTWrapper_Skill_Parry')
        {
            if (lvl > class'ZTWrapper_Skill_Parry'.default.Cfg_Damage.length)
                lvl = class'ZTWrapper_Skill_Parry'.default.Cfg_Damage.length;
            D.DamageDealtPct += class'ZTWrapper_Skill_Parry'.default.Cfg_Damage[lvl - 1];
            D.DamageResistPct += class'ZTWrapper_Skill_Parry'.default.Cfg_Resistance[lvl - 1];
            return;
        }
        if (UpgClass == class'WMUpgrade_Skill_Parry')
        {
            if (lvl > class'WMUpgrade_Skill_Parry'.default.Damage.length)
                lvl = class'WMUpgrade_Skill_Parry'.default.Damage.length;
            D.DamageDealtPct += class'WMUpgrade_Skill_Parry'.default.Damage[lvl - 1];
            D.DamageResistPct += class'WMUpgrade_Skill_Parry'.default.Resistance[lvl - 1];
            return;
        }
    }
}


//=============================================================================
// PUBLIC ENTRY POINT
//=============================================================================

/** Draw the stats panel on the canvas. Pulls WMPRI/WMGRI from KFPC. */
static simulated function DrawPanel(Canvas C, KFPlayerController KFPC)
{
    local FStatBonusData D;
    local WMPlayerReplicationInfo WMPRI;
    local WMGameReplicationInfo WMGRI;
    local ZTPlayerReplicationInfo DKPRI;
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
    DKPRI = ZTPlayerReplicationInfo(KFPC.PlayerReplicationInfo);

    if (WMPRI == None || WMGRI == None)
        return;

    // ---- ResScale (matches ZTHudWrapper curve) ----
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
    local ZTPlayerReplicationInfo DKPRI;
    local KFWeapon HeldWeapon;

    if (WMPRI == None || WMGRI == None)
        return D;

    DKPRI = ZTPlayerReplicationInfo(WMPRI);
    if (KFPC != None && KFPawn(KFPC.Pawn) != None)
        HeldWeapon = KFWeapon(KFPawn(KFPC.Pawn).Weapon);

    // ---- Perk upgrades ----
    for (i = 0; i < WMPRI.Purchase_PerkUpgrade.length; ++i)
    {
        idx = WMPRI.Purchase_PerkUpgrade[i];
        if (idx < 0 || idx >= WMGRI.PerkUpgradesList.length)
            continue;

        UpgClass = WMGRI.PerkUpgradesList[idx].PerkUpgrade;
        if (DKPRI != None)
            lvl = DKPRI.GetPerkLevel(idx);
        else if (idx < 256)
            lvl = WMPRI.bPerkUpgrade[idx].level;
        else
            lvl = 0;
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

    // ---- Weapon upgrades ----
    for (i = 0; i < WMPRI.Purchase_WeaponUpgrade.length; ++i)
    {
        idx = WMPRI.Purchase_WeaponUpgrade[i];
        if (idx < 0 || idx >= WMGRI.WeaponUpgradeSlotsList.length)
            continue;

        UpgClass = WMGRI.WeaponUpgradeSlotsList[idx].WeaponUpgrade;
        if (DKPRI != None)
            lvl = DKPRI.GetWeaponUpgrade(idx);
        else
            lvl = WMPRI.GetWeaponUpgrade(idx);

        // Weapon upgrades are not global. The combat pipeline invokes one
        // only when its registered weapon matches the held weapon, so the HUD
        // must make the same check before probing it.
        if (UpgClass != None && lvl > 0
            && IsCurrentWeaponUpgrade(WMGRI.WeaponUpgradeSlotsList[idx].KFWeapon, HeldWeapon))
        {
            ProbeUpgrade(UpgClass, lvl, KFPC, D, True);
            D.WeaponUpgCount += 1;
        }
    }

    return D;
}

/** Match the weapon-upgrade dispatch used by ZTPerk/WMPerk. Kept here so the
 * compact HUD never displays a purchased upgrade belonging to another gun. */
static function bool IsCurrentWeaponUpgrade(class<KFWeapon> WeaponClass, KFWeapon HeldWeapon)
{
    local KFPawn WeaponOwner;
    local class<KFWeapon> SingleClass;

    if (WeaponClass == None || HeldWeapon == None)
        return False;

    if (HeldWeapon.Class == WeaponClass || ClassIsChildOf(HeldWeapon.Class, WeaponClass))
        return True;

    if (KFWeap_DualBase(HeldWeapon) != None)
    {
        SingleClass = KFWeap_DualBase(HeldWeapon).SingleClass;
        if (SingleClass == WeaponClass || (SingleClass != None && ClassIsChildOf(SingleClass, WeaponClass)))
            return True;
    }

    WeaponOwner = KFPawn(HeldWeapon.Owner);
    if (WeaponOwner != None && WeaponOwner.bIsTurret && KFWeapon(WeaponOwner.Owner) != None)
    {
        if (KFWeapon(WeaponOwner.Owner).Class == WeaponClass
            || ClassIsChildOf(KFWeapon(WeaponOwner.Owner).Class, WeaponClass))
            return True;
    }

    return False;
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
static function ProbeUpgrade(class<WMUpgrade> Upg, int lvl, KFPlayerController KFPC,
    out FStatBonusData D, optional bool bWeaponSpecific)
{
    local int   iH, iArmor, iWeight, iVal, iBaseDamage, iBodyDamage, iHeadDamage;
    local float fVal, fIn;
    local KFWeapon KFW;
    local KFPawn  KFP;
    local class<KFDamageType> NoDT;
    local STraderItem EmptyTraderItem;
    local bool bHeldMelee;

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
    // Every KFWeapon owns a melee helper for bash handling, including guns.
    // IsMeleeWeapon() is KF2's authoritative weapon classification.
    bHeldMelee = KFW != None && KFW.IsMeleeWeapon();

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

    // Damage Dealt — split universal modifiers from held-weapon-only ones.
    // A no-weapon probe is the common baseline; the difference from the live
    // weapon probe is specific to this held weapon and is therefore shown as
    // MELEE or RANGED instead of incorrectly inflating universal DMG.
    if (!bWeaponSpecific)
    {
        fVal = 0.0f;
        Upg.static.ModifyDamageGivenPassive(fVal, lvl);
        D.DamageDealtPct += fVal;
        iBaseDamage = 10000;
        Upg.static.ModifyDamageGiven(iBaseDamage, 10000, lvl, , , KFPC, , 1, None);
        if (iBaseDamage != 10000)
            D.DamageDealtPct += (float(iBaseDamage) - 10000.0f) / 10000.0f;
    }
    else
    {
        // Weapon upgrades are gated by IsCurrentWeaponUpgrade() in Aggregate.
        // Their own Modify* class often does not repeat that outer gate, so a
        // no-weapon probe would falsely make a per-weapon bonus look global.
        iBaseDamage = 10000;
    }

    iBodyDamage = 10000;
    // Args: InDamage, DefaultDamage, lvl, DamageCauser=None, MyKFPM=None,
    //       DamageInstigator=KFPC, DamageType=None, HitZoneIdx=1, MyKFW=KFW
    Upg.static.ModifyDamageGiven(iBodyDamage, 10000, lvl, , , KFPC, , 1, KFW);
    if (KFW != None && iBodyDamage != iBaseDamage)
    {
        if (bHeldMelee)
            D.MeleeDamagePct += float(iBodyDamage - iBaseDamage) / 10000.0f;
        else
            D.RangedDamagePct += float(iBodyDamage - iBaseDamage) / 10000.0f;
    }

    // Headshot-only contribution. Probe the same live context twice and retain
    // only the difference, so generic damage is not duplicated in the HUD.
    iHeadDamage = 10000;
    Upg.static.ModifyDamageGiven(iHeadDamage, 10000, lvl, , , KFPC, , HZI_Head, KFW);
    if (iHeadDamage != iBodyDamage)
        D.HeadshotDamagePct += float(iHeadDamage - iBodyDamage) / 10000.0f;

    // Hard attacks are a melee fire mode. Never retain HEAVY while a pistol or
    // another ranged weapon is held, even though every KFWeapon has a bash
    // MeleeAttackHelper object.
    if (bHeldMelee)
    {
        fVal = 0.0f;
        Upg.static.ModifyHardAttackDamagePassive(fVal, lvl);
        D.HardAttackPct += fVal;
        iVal = 10000;
        Upg.static.ModifyHardAttackDamage(iVal, 10000, lvl, KFP);
        if (iVal != 10000)
            D.HardAttackPct += (float(iVal) - 10000.0f) / 10000.0f;
    }

    // Penetration — passive + non-passive. Param 4 (DamageType) is required
    // by signature; pass None placeholder so unconditional bonuses still capture.
    fVal = 0.0f;
    Upg.static.ModifyPenetrationPassive(fVal, lvl);
    D.PenetrationPct += fVal;
    fIn = 100.0f;
    Upg.static.ModifyPenetration(fIn, 100.0f, lvl, NoDT, KFP);
    if (fIn != 100.0f)
        D.PenetrationPct += (fIn - 100.0f) / 100.0f;

    // Melee speed only exists for a held melee weapon. These hooks use the
    // harmonic duration formula 1/(1/current + bonus), so the actual speed
    // bonus is (1/result)-1, not 1-result. Derived bonuses add exactly across
    // independently probed sources because their denominators are additive.
    if (bHeldMelee)
    {
        if (!bWeaponSpecific)
        {
            fVal = 1.0f;
            Upg.static.ModifyMeleeAttackSpeedPassive(fVal, lvl);
            if (fVal > 0.0f && fVal != 1.0f)
                D.MeleeSpeedPct += (1.0f / fVal) - 1.0f;
        }
        fIn = 1.0f;
        Upg.static.ModifyMeleeAttackSpeed(fIn, 1.0f, lvl, KFW);
        if (fIn > 0.0f && fIn != 1.0f)
            D.MeleeSpeedPct += (1.0f / fIn) - 1.0f;
    }

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
    if (!bWeaponSpecific)
        Upg.static.ModifyRateOfFirePassive(fVal, lvl);
    if (fVal > 0.0f && fVal != 1.0f)
        D.RateOfFirePct += (1.0f / fVal) - 1.0f;
    fIn = 1.0f;
    Upg.static.ModifyRateOfFire(fIn, 1.0f, lvl, KFW);
    if (fIn > 0.0f && fIn != 1.0f)
        D.RateOfFirePct += (1.0f / fIn) - 1.0f;

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
    return D.DamageDealtPct != 0 || D.HeadshotDamagePct != 0 || D.HardAttackPct != 0
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

static function bool HasRoguelikeData(ZTPlayerReplicationInfo DKPRI)
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
static function float MeasurePanelHeight(FStatBonusData D, ZTPlayerReplicationInfo DKPRI, float RS)
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

/** Compute ResScale matching ZTHudWrapper.ComputeResScale curve.
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

    Name="Default__ZTStatAggregator"
}
