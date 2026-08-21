// ===================================================================
// ZTUpgrade_Perk_Detonator - "The Bombardier"
//
// Each kill increments a counter. When the counter hits the rank-scaled
// threshold, the perk flips to a 10-second active window where every
// kill triggers a contact-radius detonation at the dying zed's
// location. Counter persists across waves.
//
//   Threshold:  30 - (rank * 0.75)  -- 30 at R0, 15 at R20
//   Window:     10 seconds (extended by Hair Trigger)
//   Damage:     400 + (rank * 30)   -- 400 at R0, 1000 at R20
//   Radius:     300 + (rank * 5)    -- 300 at R0, 400 at R20
//
// Self-damage is filtered (KFPawn_Human ignored by the projectile).
//
// Skills:
//   - Hair Trigger:   threshold reduction + window extension
//   - Slow Burn:      ground fire pool after detonation
//   - Apex Charge:    boss-kill specials (instant fill, multipliers, bank)
//   - Daisy Chain:    tag survivors; tagged death chains a detonation
// ===================================================================
class ZTUpgrade_Perk_Detonator extends ZTUpgrade_Perk config(ZedternalUnlimited_Balance);

// ===================================================================
// CONFIGURABLE BALANCE (per-level passives)
// ===================================================================

var config float DamagePerLevel;       // +2% all-weapon damage per level (40% at L20)
var config float SpareAmmoPerLevel;    // +2% spare ammo per level (40% at L20)
var config int MODEVERSION;

static function UpdateConfig()
{
    if (default.MODEVERSION < 1)
    {
        default.DamagePerLevel = 0.02f;
        default.SpareAmmoPerLevel = 0.02f;

        default.MODEVERSION = 1;
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

// Spare ammo multiplier -- additive accumulation matches Artificer's damage pattern.
// At L20 with 0.02f: spareAmmoFactor += 0.4 -> +40% spare ammo on every weapon.
static simulated function ModifySpareAmmoAmountPassive(out float spareAmmoFactor, int upgLevel)
{
    spareAmmoFactor += default.SpareAmmoPerLevel * upgLevel;
}

// ===================================================================
// HELPER MANAGEMENT (mirrors Gambit pattern)
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Detonator_Helper H;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Detonator_Helper', H)
        {
            bFound = True;
            H.SetPerkLevel(upgLevel);
            break;
        }

        if (!bFound)
        {
            H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Detonator_Helper', OwnerPawn);
            H.SetPerkLevel(upgLevel);
        }
    }
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Detonator_Helper H;
    local KFPlayerController KFPC;
    local ZTHudWrapper HUD;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Detonator_Helper', H)
        {
            H.Destroy();
        }

        // Clear Detonator card from HUD wrapper
        KFPC = KFPlayerController(OwnerPawn.GetALocalPlayerController());
        if (KFPC != None && KFPC.myHUD != None)
        {
            HUD = ZTHudWrapper(KFPC.myHUD);
            if (HUD != None)
                HUD.ClearDetonatorDisplay();
        }
    }
}

// GetHelper spawns if missing (server-side). Mirrors Gambit.
static function ZTUpgrade_Perk_Detonator_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Detonator_Helper H;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Detonator_Helper', H)
        {
            return H;
        }

        H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Detonator_Helper', OwnerPawn);
    }

    return H;
}

// Non-spawning helper lookup -- returns None if player doesn't have Detonator.
// Used by NotifyZedKilled to avoid creating helpers for non-Detonator players.
static function ZTUpgrade_Perk_Detonator_Helper FindHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Detonator_Helper H;

    if (KFPawn_Human(OwnerPawn) == None)
        return None;

    foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Detonator_Helper', H)
    {
        return H;
    }

    return None;
}

// ===================================================================
// KILL NOTIFICATION -- Called from GameInfo.Killed() for every confirmed zed death.
// This is the AUTHORITATIVE kill hook -- ModifyDamageGiven is unreliable
// (misses multikills, explosions, DoT, penetration, turret kills).
// Mirrors ZTUpgrade_Perk_Artificer.NotifyZedKilled.
// ===================================================================

static function NotifyZedKilled(Controller Killer, Pawn KilledPawn, class<DamageType> DT)
{
    local ZTUpgrade_Perk_Detonator_Helper H;
    local KFPawn_Human KFPH;
    local KFPawn_Monster KFPM;

    if (Killer == None || Killer.Pawn == None)
        return;

    KFPM = KFPawn_Monster(KilledPawn);
    if (KFPM == None)
        return;

    KFPH = KFPawn_Human(Killer.Pawn);
    if (KFPH == None)
        return;

    // IMPORTANT: Use FindHelper (non-spawning) -- skip players without the perk.
    H = FindHelper(KFPH);
    if (H == None)
        return;

    // Weapon arg is unused for Detonator (no per-weapon logic). Pass None.
    H.OnZedKilled(KFPM, None);
}

// ===================================================================
// DAMAGE GIVEN -- Level refresh only
// Kill detection moved to NotifyZedKilled / GameInfo.Killed() for accuracy.
// We still call this every damage event to keep helper.PerkLevel fresh
// in case the player levels the perk mid-wave (roguelike upgrade card).
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
    optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
    optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
    optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Detonator_Helper H;

    if (DamageInstigator == None || DamageInstigator.Pawn == None)
        return;

    H = GetHelper(DamageInstigator.Pawn);
    if (H != None)
        H.SetPerkLevel(upgLevel);
}

// ===================================================================
// HUD -- All rendering handled by ZTHudWrapper.DrawDetonatorCard()
// ===================================================================

static simulated function DrawOnHUD(int upgLevel, Canvas C, KFPawn OwnerPawn)
{
    // Intentionally empty -- ZTHudWrapper handles all Detonator HUD rendering.
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Rank_0'
    // Localization (Phase 2: smart fallback pattern).
    //   - bShouldLocalize=True engages the ZR loc routing in the UI.
    //   - Our ZTUpgrade_Perk override of GetUpgradeName / GetUpgradeDescription
    //     tries Localize() first, falls back to the literal English defaults
    //     below if .int is missing or key is unresolved.
    //   - Translation file: KFGame/Localization/<lang>/ZedternalTempered.<langext>
    //     Section: [ZTUpgrade_Perk_Detonator]
    //     Keys: UpgradeName, PerkUpgradeDescription1..5
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Detonator"
    LocalizeDescriptionLineCount=5    // tells ZR's UI how many description lines to render via the loc path

    // English literals -- used as fallback when no .int is installed.
    UpgradeName="Detonator"
    upgradeDescription(0)="<font color=\"#FFD700\">Detonation Mastery:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FFD700\">All Weapon Damage</font>"
    upgradeDescription(1)="<font color=\"#FFD700\">Detonation Mastery:</font> <font color=\"#FFFFFF\">+%x%%</font> <font color=\"#FFD700\">Spare Ammo</font>"
    upgradeDescription(2)="Each kill charges the <font color=\"#FF8C32\">Counter</font>. At threshold, you enter a <font color=\"#FF4444\">10s active window</font> where kills <font color=\"#FF4444\">detonate</font> at the zed's location."
    upgradeDescription(3)="Threshold scales from <font color=\"#FFFFFF\">50 -> 30</font> kills, detonation damage from <font color=\"#FFFFFF\">400 -> 1000</font>, and radius from <font color=\"#FFFFFF\">300 -> 400</font>."
    upgradeDescription(4)="Counter <font color=\"#77d914\">persists across waves</font>. Self-damage is filtered."

    // PerkBonus tokens for %x interpolation in descriptions(0) and (1).
    // Display value = baseValue + incValue * level.
    PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Damage % per level
    PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Spare Ammo % per level


	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Detonator"
}
