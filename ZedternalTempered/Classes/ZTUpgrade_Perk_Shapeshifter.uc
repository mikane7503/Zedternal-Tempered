// ===================================================================
// ZTUpgrade_Perk_Shapeshifter - "The Living Dice Roll"
//
// Provides NO inherent bonuses. At wave start, a random buff from the
// pool of 15 is applied. Each perk level strengthens the buff.
//
// Rank 1-9:  One random buff per wave (replaces previous)
// Rank 10-19: Two random buffs per wave (both replace previous pair)
// Rank 20:   One buff per wave, STACKS permanently ("Mimicry")
//            Once all 15 collected, no more rolls.
//
// BUFF EFFECTIVENESS SYSTEM:
// All Modify* functions use GetBuffEffectiveness() which returns a
// 0.0-N.0 float combining: active state, residual echoes (Residual
// Form), buff amplification (Overclocked Form), ZED time boost (Flux
// State), and single-buff focus (Monomorph). This allows skill
// upgrades to modify buff behavior without changing this file.
//
// BUFF POOL (15 total - all hooks have OwnerPawn access):
// ---------------------------------------------------------------
// #0  Carnage       +3% all damage /lvl         Weight 10
// #1  Executioner   +5% headshot damage /lvl     Weight 10
// #2  Rampage       +3% fire rate /lvl           Weight 10
// #3  Crusher       +5% heavy melee dmg /lvl     Weight 7
// #4  Berserker     +3% melee speed /lvl         Weight 7
// #5  Fortress      -2% damage taken /lvl        Weight 10
// #6  Leech         +1 HP on kill /lvl           Weight 4
// #7  Anchor        -3% recoil /lvl              Weight 10
// #8  Hawk          -3% spread /lvl              Weight 7
// #9  Speedloader   +3% reload speed /lvl        Weight 10
// #10 Switchblade   +3% weapon switch /lvl       Weight 7
// #11 Speedfreak    +2% move speed /lvl          Weight 10
// #12 Hoarder       +5% spare ammo /lvl          Weight 10
// #13 Drumfire      +3% mag size /lvl            Weight 7
// #14 Phantom       +5% ZED time fire rate /lvl  Weight 4
// ===================================================================
class ZTUpgrade_Perk_Shapeshifter extends ZTUpgrade_Perk config(ZedternalUnlimited_Balance);

// ===================================================================
// BUFF SCALING - Per-Level Increments
// ===================================================================

// Offense
var config float Buff_Carnage_PerLevel;            // #0  +3% all damage
var config float Buff_Executioner_PerLevel;         // #1  +5% headshot damage
var config float Buff_Rampage_PerLevel;             // #2  +3% fire rate
var config float Buff_Crusher_PerLevel;             // #3  +5% heavy melee damage
var config float Buff_Berserker_PerLevel;           // #4  +3% melee attack speed

// Defense
var config float Buff_Fortress_PerLevel;            // #5  -2% damage taken
var config int   Buff_Leech_PerLevel;               // #6  +1 HP on kill

// Handling
var config float Buff_Anchor_PerLevel;              // #7  -3% recoil
var config float Buff_Hawk_PerLevel;                // #8  -3% spread
var config float Buff_Speedloader_PerLevel;         // #9  +3% reload speed
var config float Buff_Switchblade_PerLevel;         // #10 +3% weapon switch speed

// Utility
var config float Buff_Speedfreak_PerLevel;          // #11 +2% movement speed
var config float Buff_Hoarder_PerLevel;             // #12 +5% spare ammo
var config float Buff_Drumfire_PerLevel;            // #13 +3% magazine size

// Special
var config float Buff_Phantom_PerLevel;             // #14 +5% ZED time fire rate

// Total buff count
var const int TOTAL_BUFF_COUNT;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Buff_Carnage_PerLevel = 0.03f;
		default.Buff_Executioner_PerLevel = 0.05f;
		default.Buff_Rampage_PerLevel = 0.03f;
		default.Buff_Crusher_PerLevel = 0.05f;
		default.Buff_Berserker_PerLevel = 0.03f;
		default.Buff_Fortress_PerLevel = 0.01f;
		default.Buff_Leech_PerLevel = 1;
		default.Buff_Anchor_PerLevel = 0.03f;
		default.Buff_Hawk_PerLevel = 0.03f;
		default.Buff_Speedloader_PerLevel = 0.03f;
		default.Buff_Switchblade_PerLevel = 0.03f;
		default.Buff_Speedfreak_PerLevel = 0.02f;
		default.Buff_Hoarder_PerLevel = 0.05f;
		default.Buff_Drumfire_PerLevel = 0.03f;
		default.Buff_Phantom_PerLevel = 0.05f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Buff_Fortress_PerLevel = 0.010000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// HELPER MANAGEMENT
//
// Uses ChildActors first (fast, works on server where helper was spawned).
// Falls back to DynamicActors + Owner check for client-side lookups,
// because replicated actors may not appear in ChildActors on clients.
// ===================================================================

static simulated function ZTUpgrade_Perk_Shapeshifter_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local PlayerReplicationInfo TargetPRI;

    if (OwnerPawn == None)
        return None;

    // Primary: ChildActors (fast, works on server/listen-server)
    foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Shapeshifter_Helper', Helper)
    {
        return Helper;
    }

    // Fallback: DynamicActors with Owner check
    foreach OwnerPawn.DynamicActors(class'ZTUpgrade_Perk_Shapeshifter_Helper', Helper)
    {
        if (Helper.Owner == OwnerPawn)
            return Helper;
    }

    // Client fallback: Owner reference can mismatch on clients.
    // Match on PlayerReplicationInfo instead, which is always consistent.
    TargetPRI = OwnerPawn.PlayerReplicationInfo;
    if (TargetPRI != None)
    {
        foreach OwnerPawn.DynamicActors(class'ZTUpgrade_Perk_Shapeshifter_Helper', Helper)
        {
            if (Helper.OwnerPRI == TargetPRI)
                return Helper;
        }
    }

    return None;
}

static function ZTUpgrade_Perk_Shapeshifter_Helper SpawnHelper(Pawn OwnerPawn, int upgLevel)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;

    if (OwnerPawn == None)
        return None;

    // Server-only: helpers must only be spawned on the authority
    if (OwnerPawn.Role != ROLE_Authority)
        return None;

    Helper = GetHelper(OwnerPawn);
    if (Helper != None)
    {
        Helper.SetPerkLevel(upgLevel);
        return Helper;
    }

    Helper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Shapeshifter_Helper', OwnerPawn);
    if (Helper != None)
    {
        Helper.SetPerkLevel(upgLevel);
    }

    return Helper;
}

// ===================================================================
// INITIATE WEAPON - Spawns helper on first weapon pickup
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    SpawnHelper(OwnerPawn, upgLevel);
}

// ===================================================================
// WAVE END - Only update perk level (buff rolling handled by Helper polling)
// ===================================================================

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;

    if (KFPC == None || KFPC.Pawn == None)
        return;

    Helper = GetHelper(KFPC.Pawn);
    if (Helper != None)
    {
        Helper.SetPerkLevel(upgLevel);
    }
}

// ===================================================================
// HELPER: Resolve OwnerPawn from a KFWeapon
// Tries Owner first (more reliable for inventory items), then Instigator.
// ===================================================================

static simulated function KFPawn GetWeaponOwnerPawn(KFWeapon KFW)
{
    local KFPawn P;
    local Controller C;

    if (KFW == None)
        return None;

    // Method 1: Instigator (most reliable in KF2 - set to owning Pawn)
    P = KFPawn(KFW.Instigator);
    if (P != None)
        return P;

    // Method 2: Direct Owner cast
    P = KFPawn(KFW.Owner);
    if (P != None)
        return P;

    // Method 3: Owner might be a Controller
    C = Controller(KFW.Owner);
    if (C != None)
    {
        P = KFPawn(C.Pawn);
        if (P != None)
            return P;
    }

    // Method 4: Through InventoryManager
    if (KFW.InvManager != None)
    {
        P = KFPawn(KFW.InvManager.Owner);
        if (P != None)
            return P;
    }

    return None;
}

// ===================================================================
// #0 CARNAGE: +3% all damage per level
// #1 EXECUTIONER: +5% headshot damage per level
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local float TotalBonus;
    local float Effect;

    if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None)
        return;

    Helper = GetHelper(DamageInstigator.Pawn);
    if (Helper == None)
        return;

    TotalBonus = 0.0f;

    // #0 Carnage - all damage
    Effect = Helper.GetBuffEffectiveness(0);
    if (Effect > 0.0f)
        TotalBonus += default.Buff_Carnage_PerLevel * upgLevel * Effect;

    // #1 Executioner - headshot only
    if (HitZoneIdx == HZI_HEAD)
    {
        Effect = Helper.GetBuffEffectiveness(1);
        if (Effect > 0.0f)
            TotalBonus += default.Buff_Executioner_PerLevel * upgLevel * Effect;
    }

    if (TotalBonus > 0.0f)
        InDamage += Round(float(DefaultDamage) * TotalBonus);
}

// ===================================================================
// #2 RAMPAGE: +3% fire rate per level
// Uses reciprocal formula for proper stacking with other perks.
// ===================================================================

static simulated function ModifyRateOfFire(out float InRate, float DefaultRate, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local KFPawn OwnerPawn;
    local float Effect;

    OwnerPawn = GetWeaponOwnerPawn(KFW);
    if (OwnerPawn == None)
        return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None)
        return;

    Effect = Helper.GetBuffEffectiveness(2);
    if (Effect > 0.0f)
        InRate = DefaultRate / (DefaultRate / InRate + default.Buff_Rampage_PerLevel * upgLevel * Effect);
}

// ===================================================================
// #3 CRUSHER: +5% hard attack damage per level
// ===================================================================

static function ModifyHardAttackDamage(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local float Effect;

    if (OwnerPawn == None) return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(3);
    if (Effect > 0.0f)
        InDamage += Round(float(DefaultDamage) * (default.Buff_Crusher_PerLevel * upgLevel * Effect));
}

// ===================================================================
// #4 BERSERKER: +3% melee attack speed per level
// Uses reciprocal formula for proper stacking.
// ===================================================================

static simulated function ModifyMeleeAttackSpeed(out float InDuration, float DefaultDuration, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local KFPawn OwnerPawn;
    local float Effect;

    OwnerPawn = GetWeaponOwnerPawn(KFW);
    if (OwnerPawn == None)
        return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(4);
    if (Effect > 0.0f)
        InDuration = DefaultDuration / (DefaultDuration / InDuration + default.Buff_Berserker_PerLevel * upgLevel * Effect);
}

// ===================================================================
// #5 FORTRESS: -2% damage taken per level (capped at 50%)
// ===================================================================

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local float Effect;

    if (OwnerPawn == None) return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(5);
    if (Effect > 0.0f)
		InDamage -= Round(float(DefaultDamage) * FMin(default.Buff_Fortress_PerLevel * upgLevel * Effect, 0.25f));
}

// ===================================================================
// #6 LEECH: +1 HP on kill per level
// ===================================================================

static function AddVampireHealth(out int InHealth, int DefaultHealth, int upgLevel, KFPlayerController KFPC, class<DamageType> DT)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local float Effect;

    if (KFPC == None || KFPC.Pawn == None)
        return;

    Helper = GetHelper(KFPC.Pawn);
    if (Helper == None)
        return;

    Effect = Helper.GetBuffEffectiveness(6);
    if (Effect > 0.0f)
    {
        InHealth += Round(float(default.Buff_Leech_PerLevel * upgLevel) * Effect);
    }
}

// ===================================================================
// #7 ANCHOR: -3% recoil per level (capped at 75%)
// ===================================================================

static simulated function ModifyRecoil(out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local KFPawn OwnerPawn;
    local float Effect;

    OwnerPawn = GetWeaponOwnerPawn(KFW);
    if (OwnerPawn == None)
        return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(7);
    if (Effect > 0.0f)
        InRecoilModifier -= DefaultRecoilModifier * FMin(default.Buff_Anchor_PerLevel * upgLevel * Effect, 0.75f);
}

// ===================================================================
// #8 HAWK: -3% spread per level (capped at 75%)
// ===================================================================

static simulated function ModifySpread(out float InSpreadModifier, float DefaultSpreadModifier, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local KFPawn OwnerPawn;
    local float Effect;

    OwnerPawn = GetWeaponOwnerPawn(KFW);
    if (OwnerPawn == None)
        return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(8);
    if (Effect > 0.0f)
        InSpreadModifier -= DefaultSpreadModifier * FMin(default.Buff_Hawk_PerLevel * upgLevel * Effect, 0.75f);
}

// ===================================================================
// #9 SPEEDLOADER: +3% reload speed per level
// Uses reciprocal formula (lower scale = faster reload).
// ===================================================================

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local float Effect;

    if (OwnerPawn == None) return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(9);
    if (Effect > 0.0f)
        InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + default.Buff_Speedloader_PerLevel * upgLevel * Effect);
}

// ===================================================================
// #10 SWITCHBLADE: +3% weapon switch speed per level
// Uses reciprocal formula (lower time = faster switch).
// ===================================================================

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime, float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local KFPawn OwnerPawn;
    local float Effect;

    OwnerPawn = GetWeaponOwnerPawn(KFW);
    if (OwnerPawn == None)
        return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(10);
    if (Effect > 0.0f)
        InSwitchTime = DefaultSwitchTime / (DefaultSwitchTime / InSwitchTime + default.Buff_Switchblade_PerLevel * upgLevel * Effect);
}

// ===================================================================
// #11 SPEEDFREAK: +2% movement speed per level
// ===================================================================

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local float Effect;

    if (OwnerPawn == None) return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(11);
    if (Effect > 0.0f)
        InSpeed += DefaultSpeed * (default.Buff_Speedfreak_PerLevel * upgLevel * Effect);
}

// ===================================================================
// #12 HOARDER: +5% spare ammo per level
// ===================================================================

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=False)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local KFPawn OwnerPawn;
    local float Effect;

    OwnerPawn = GetWeaponOwnerPawn(KFW);
    if (OwnerPawn == None)
        return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(12);
    if (Effect > 0.0f)
        InSpareAmmo += Round(float(DefaultSpareAmmo) * (default.Buff_Hoarder_PerLevel * upgLevel * Effect));
}

// ===================================================================
// #13 DRUMFIRE: +3% magazine size per level
// ===================================================================

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local KFPawn OwnerPawn;
    local float Effect;

    OwnerPawn = GetWeaponOwnerPawn(KFW);
    if (OwnerPawn == None)
        return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(13);
    if (Effect > 0.0f)
        InMagazineCapacity += Round(float(DefaultMagazineCapacity) * (default.Buff_Drumfire_PerLevel * upgLevel * Effect));
}

// ===================================================================
// #14 PHANTOM: +5% ZED time fire rate modifier per level
// ===================================================================

static simulated function GetZedTimeModifier(out float InModifier, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Shapeshifter_Helper Helper;
    local KFPawn OwnerPawn;
    local float Effect;

    OwnerPawn = GetWeaponOwnerPawn(KFW);
    if (OwnerPawn == None)
        return;

    Helper = GetHelper(OwnerPawn);
    if (Helper == None) return;

    Effect = Helper.GetBuffEffectiveness(14);
    if (Effect > 0.0f)
        InModifier += default.Buff_Phantom_PerLevel * upgLevel * Effect;
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Shapeshifter_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Shapeshifter]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Shapeshifter"
    LocalizeDescriptionLineCount=3

    TOTAL_BUFF_COUNT=15

    // Offense

    // Defense

    // Handling

    // Utility

    // Special

    // Perk display
    UpgradeName="Shapeshifter"
    UpgradeDescription(0)="<font color=\"#c77dff\">Shapeshifter:</font> Each wave grants a <font color=\"#e0aaff\">random combat buff</font> that scales with level"
    UpgradeDescription(1)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Dual Form</font> - You now receive <font color=\"#e0aaff\">two buffs</font> per wave"
    UpgradeDescription(2)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Mimicry</font> - Buffs <font color=\"#e0aaff\">stack permanently</font>. Collect all <font color=\"#FFFFFF\">15</font> to achieve mastery"

	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Shapeshifter"
}
