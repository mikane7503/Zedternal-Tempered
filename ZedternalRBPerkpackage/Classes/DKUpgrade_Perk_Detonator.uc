// ===================================================================
// DKUpgrade_Perk_Detonator - "The Bombardier"
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
class DKUpgrade_Perk_Detonator extends DKUpgrade_Perk
    config(ZedternalUnlimited_Balance);

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
    local DKUpgrade_Perk_Detonator_Helper H;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Detonator_Helper', H)
        {
            bFound = True;
            H.SetPerkLevel(upgLevel);
            break;
        }

        if (!bFound)
        {
            H = OwnerPawn.Spawn(class'DKUpgrade_Perk_Detonator_Helper', OwnerPawn);
            H.SetPerkLevel(upgLevel);
        }
    }
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Detonator_Helper H;
    local KFPlayerController KFPC;
    local DKHudWrapper HUD;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Detonator_Helper', H)
        {
            H.Destroy();
        }

        // Clear Detonator card from HUD wrapper
        KFPC = KFPlayerController(OwnerPawn.GetALocalPlayerController());
        if (KFPC != None && KFPC.myHUD != None)
        {
            HUD = DKHudWrapper(KFPC.myHUD);
            if (HUD != None)
                HUD.ClearDetonatorDisplay();
        }
    }
}

// GetHelper spawns if missing (server-side). Mirrors Gambit.
static function DKUpgrade_Perk_Detonator_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Detonator_Helper H;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Detonator_Helper', H)
        {
            return H;
        }

        H = OwnerPawn.Spawn(class'DKUpgrade_Perk_Detonator_Helper', OwnerPawn);
    }

    return H;
}

// Non-spawning helper lookup -- returns None if player doesn't have Detonator.
// Used by NotifyZedKilled to avoid creating helpers for non-Detonator players.
static function DKUpgrade_Perk_Detonator_Helper FindHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Detonator_Helper H;

    if (KFPawn_Human(OwnerPawn) == None)
        return None;

    foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Detonator_Helper', H)
    {
        return H;
    }

    return None;
}

// ===================================================================
// KILL NOTIFICATION -- Called from GameInfo.Killed() for every confirmed zed death.
// This is the AUTHORITATIVE kill hook -- ModifyDamageGiven is unreliable
// (misses multikills, explosions, DoT, penetration, turret kills).
// Mirrors DKUpgrade_Perk_Artificer.NotifyZedKilled.
// ===================================================================

static function NotifyZedKilled(Controller Killer, Pawn KilledPawn, class<DamageType> DT)
{
    local DKUpgrade_Perk_Detonator_Helper H;
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
    local DKUpgrade_Perk_Detonator_Helper H;

    if (DamageInstigator == None || DamageInstigator.Pawn == None)
        return;

    H = GetHelper(DamageInstigator.Pawn);
    if (H != None)
        H.SetPerkLevel(upgLevel);
}

// ===================================================================
// HUD -- All rendering handled by DKHudWrapper.DrawDetonatorCard()
// ===================================================================

static simulated function DrawOnHUD(int upgLevel, Canvas C, KFPawn OwnerPawn)
{
    // Intentionally empty -- DKHudWrapper handles all Detonator HUD rendering.
}

defaultproperties
{
    // Localization (Phase 2: smart fallback pattern).
    //   - bShouldLocalize=True engages the ZR loc routing in the UI.
    //   - Our DKUpgrade_Perk override of GetUpgradeName / GetUpgradeDescription
    //     tries Localize() first, falls back to the literal English defaults
    //     below if .int is missing or key is unresolved.
    //   - Translation file: KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    //     Section: [DKUpgrade_Perk_Detonator]
    //     Keys: UpgradeName, PerkUpgradeDescription1..5
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Detonator"
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

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_0'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_1'
	UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_2'
	UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_3'
	UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_4'
	UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'


	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Detonator_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_Detonator"
}
