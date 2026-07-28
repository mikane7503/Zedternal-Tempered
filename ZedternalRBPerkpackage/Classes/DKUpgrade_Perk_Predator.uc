// ===================================================================
// DKUpgrade_Perk_Predator - The Hunt Is On
//
// Trophy hunting perk. Kill zeds to drop trophies, collect trophies,
// complete sets for powerful bonuses. Scales with perk level.
//
// Passive: +1.5% damage per level
// L10 Keen Eye: double drop chance
// L20 Trophy Master: 5% drops + double set bonuses
//
// PHASES:
//   1. Set Phase: Collect unique trophies → complete sets (max 3)
//   2. Stacking Phase: After 3 sets, infinite trophy stacking with
//      per-category bonuses in 5 slots
//
// All dynamic bonuses come from DKUpgrade_Perk_Predator_Helper
// via accumulated Acc* fields read by these static hooks.
// ===================================================================
class DKUpgrade_Perk_Predator extends DKUpgrade_Perk
	config(ZedternalUnlimited);

// Passive damage per level
var config float Damage;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Damage = 0.015f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Predator_Helper H;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        H = GetHelper(OwnerPawn);
        if (H == None)
        {
            H = OwnerPawn.Spawn(class'DKUpgrade_Perk_Predator_Helper', OwnerPawn);
            if (H != None)
                H.SetPerkLevel(upgLevel);
        }
    }
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Predator_Helper H;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Predator_Helper', H)
        {
            H.Destroy();
        }
    }
}

// ===================================================================
// HELPER LOOKUP
//
// Uses ChildActors first (fast, works on server/listen-server).
// Falls back to DynamicActors + Owner check for client-side lookups,
// because replicated actors may not appear in ChildActors on clients.
// NEVER spawns — returns None if not found (spawning is in InitiateWeapon).
// ===================================================================

static simulated function DKUpgrade_Perk_Predator_Helper GetHelper(Pawn OwnerPawn)
{
    local DKUpgrade_Perk_Predator_Helper H;
    local PlayerReplicationInfo TargetPRI;

    if (OwnerPawn == None)
        return None;

    // Primary: ChildActors (fast, works on server/listen-server)
    foreach OwnerPawn.ChildActors(class'DKUpgrade_Perk_Predator_Helper', H)
    {
        return H;
    }

    // Fallback 1: DynamicActors with Owner check (replicated actors on clients)
    foreach OwnerPawn.DynamicActors(class'DKUpgrade_Perk_Predator_Helper', H)
    {
        if (H.Owner == OwnerPawn)
            return H;
    }

    // Fallback 2: PRI match (Owner reference can mismatch on clients)
    TargetPRI = OwnerPawn.PlayerReplicationInfo;
    if (TargetPRI != None)
    {
        foreach OwnerPawn.DynamicActors(class'DKUpgrade_Perk_Predator_Helper', H)
        {
            if (H.Player != None && H.Player.PlayerReplicationInfo == TargetPRI)
                return H;
        }
    }

    return None;
}

// ===================================================================
// DAMAGE GIVEN - Passive + Set bonuses + Stacking bonuses
//
// AccAllDamage:      Set bonuses + FP stacking (+10% per stack)
// AccLargeZedDamage: Set bonuses (Big Game)
// AccMeleeDamage:    Set bonuses (Blade Collector) + Gorefast stacking (+1%)
// AccHeadshotDamage: EDAR stacking (+10% per stack)
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
    optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
    optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
    optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Predator_Helper H;
    local KFPawn_Human KFPH;

    // Passive: +1.5% per level
    InDamage += DefaultDamage * (default.Damage * float(upgLevel));

    // Resolve owning pawn: prefer DamageInstigator, fall back to weapon owner
    if (DamageInstigator != None)
        KFPH = KFPawn_Human(DamageInstigator.Pawn);

    if (KFPH == None && MyKFW != None)
        KFPH = KFPawn_Human(MyKFW.Instigator);

    if (KFPH == None && DamageCauser != None)
        KFPH = KFPawn_Human(DamageCauser.Instigator);

    if (KFPH == None)
        return;

    H = GetHelper(KFPH);
    if (H == None)
        return;

    // Accumulated all-damage bonus (sets + FP stacking)
    if (H.AccAllDamage > 0.0f)
        InDamage += DefaultDamage * H.AccAllDamage;

    // Accumulated large zed damage bonus (sets only)
    if (H.AccLargeZedDamage > 0.0f && MyKFPM != None)
    {
        if (MyKFPM.IsABoss() || MyKFPM.bLargeZed)
            InDamage += DefaultDamage * H.AccLargeZedDamage;
    }

    // Accumulated melee damage bonus (sets + Gorefast stacking)
    if (H.AccMeleeDamage > 0.0f && DamageType != None && static.IsMeleeDamageType(DamageType))
        InDamage += DefaultDamage * H.AccMeleeDamage;

    // Accumulated headshot damage bonus (EDAR stacking)
    if (H.AccHeadshotDamage > 0.0f && HitZoneIdx == HZI_HEAD)
        InDamage += DefaultDamage * H.AccHeadshotDamage;

    // Kill detection: if this damage is lethal, notify the helper
    if (MyKFPM != None && InDamage >= MyKFPM.Health && DamageInstigator != None && DamageInstigator.Pawn != None)
        H.OnZedKilled(MyKFPM);
}

// ===================================================================
// DAMAGE TAKEN - AccDamageResist (sets + Husk stacking)
// ===================================================================

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel,
    KFPawn OwnerPawn, optional class<DamageType> DamageType,
    optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    local DKUpgrade_Perk_Predator_Helper H;

    H = GetHelper(OwnerPawn);
    if (H != None && H.AccDamageResist > 0.0f)
        InDamage -= DefaultDamage * H.AccDamageResist;

    if (InDamage < 0)
        InDamage = 0;
}

// ===================================================================
// MOVEMENT SPEED - AccSpeed (sets + Crawler stacking)
// ===================================================================

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed,
    int upgLevel, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Predator_Helper H;

    H = GetHelper(OwnerPawn);
    if (H != None && H.AccSpeed > 0.0f)
        InSpeed += DefaultSpeed * H.AccSpeed;
}

// ===================================================================
// RELOAD SPEED - AccReload (sets only, no stacking category)
// ===================================================================

static simulated function GetReloadRateScale(out float InReloadRateScale,
    int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Predator_Helper H;

    H = GetHelper(OwnerPawn);
    if (H != None && H.AccReload > 0.0f)
    {
        InReloadRateScale -= H.AccReload;
        if (InReloadRateScale < 0.3f)
            InReloadRateScale = 0.3f;
    }
}

// ===================================================================
// MAGAZINE SIZE - AccMagSize (sets + Stalker stacking)
// ===================================================================

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity,
    int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW,
    optional array< class<KFPerk> > WeaponPerkClass, optional bool bSecondary,
    optional name WeaponClassname)
{
    local DKUpgrade_Perk_Predator_Helper H;

    if (KFW == None || KFW.Instigator == None)
        return;

    H = GetHelper(KFPawn(KFW.Instigator));
    if (H != None && H.AccMagSize > 0.0f)
        InMagazineCapacity += Round(float(DefaultMagazineCapacity) * H.AccMagSize);
}

// ===================================================================
// WEAPON SWITCH TIME - AccWeaponSwitch (sets only)
// ===================================================================

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime,
    float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
    local DKUpgrade_Perk_Predator_Helper H;

    if (KFW == None || KFW.Instigator == None)
        return;

    H = GetHelper(KFPawn(KFW.Instigator));
    if (H != None && H.AccWeaponSwitch > 0.0f)
    {
        InSwitchTime -= DefaultSwitchTime * H.AccWeaponSwitch;
        if (InSwitchTime < 0.1f)
            InSwitchTime = 0.1f;
    }
}

// ===================================================================
// SPARE AMMO - AccSpareAmmo (sets + Siren stacking)
// ===================================================================

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo,
    int DefaultSpareAmmo, int upgLevel, KFWeapon KFW,
    optional const out STraderItem TraderItem, optional bool bSecondary)
{
    local DKUpgrade_Perk_Predator_Helper H;

    if (KFW == None || KFW.Instigator == None)
        return;

    H = GetHelper(KFPawn(KFW.Instigator));
    if (H != None && H.AccSpareAmmo > 0.0f)
        InSpareAmmo += Round(float(DefaultSpareAmmo) * H.AccSpareAmmo);
}

// ===================================================================
// GRAB IMMUNITY
// ===================================================================

static function bool CanNotBeGrabbed(int upgLevel, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Predator_Helper H;

    H = GetHelper(OwnerPawn);
    if (H != None)
        return H.bCanNotBeGrabbed;

    return False;
}

// ===================================================================
// SEE ENEMY HEALTH
// ===================================================================

static simulated function bool CanSeeEnemyHealth(int upgLevel, KFPawn OwnerPawn)
{
    local DKUpgrade_Perk_Predator_Helper H;

    H = GetHelper(OwnerPawn);
    if (H != None)
        return H.bCanSeeEnemyHealth;

    return False;
}

// ===================================================================
// WAVE END - Update perk level, cleanup pickups, award stacking dosh
// ===================================================================

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local DKUpgrade_Perk_Predator_Helper H;

    if (KFPC != None && KFPC.Pawn != None)
    {
        H = GetHelper(KFPawn(KFPC.Pawn));
        if (H != None)
        {
            H.CleanupPickups();

            // Stacking Dosh bonus: Clot stacks grant dosh per wave
            if (H.StackBonusDosh > 0)
            {
                KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo).AddDosh(H.StackBonusDosh);
                `log("[DK_PREDATOR] Wave-end dosh bonus:" @ H.StackBonusDosh);
            }

            H.SetPerkLevel(upgLevel);
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
    // Section: [DKUpgrade_Perk_Predator]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_Predator"
    LocalizeDescriptionLineCount=9

    UpgradeName="Predator"
    UpgradeDescription(0)="<font color=\"#CC8800\">Hunter's Instinct:</font> <font color=\"#FFFFFF\">+1.5%%</font> <font color=\"#FF6666\">All Damage</font> per rank"
    UpgradeDescription(1)="<font color=\"#CC8800\">Trophy Hunter:</font> Killing zeds has a chance to <font color=\"#FFD700\">drop trophies</font>. Collect matching trophies to complete <font color=\"#87CEEB\">sets</font> (max <font color=\"#FFFFFF\">3</font>) for permanent bonuses"
    UpgradeDescription(2)="<font color=\"#87CEEB\">Tier 1 (2-piece):</font> <font color=\"#FFD700\">Swarm Breaker</font> Clot+Crawler <font color=\"#FFFFFF\">+15%% Speed</font>   <font color=\"#FFD700\">Blade Collector</font> Gorefast+Stalker <font color=\"#FFFFFF\">+30%% Melee Damage</font>   <font color=\"#FFD700\">Freak Show</font> Siren+Husk <font color=\"#FFFFFF\">+25%% Resist</font>   <font color=\"#FFD700\">Salvage Run</font> EDAR+Bloat <font color=\"#FFFFFF\">+25%% Reload</font>   <font color=\"#FFD700\">Big Game</font> Scrake+FP <font color=\"#FFFFFF\">+25%% Large Zed Damage</font>"
    UpgradeDescription(3)="<font color=\"#87CEEB\">Tier 2 (3-piece):</font> <font color=\"#FFD700\">Full Sweep</font> Clot+Gorefast+Crawler <font color=\"#FFFFFF\">+30%% Magazine Size</font>   <font color=\"#FFD700\">Night Stalker</font> Stalker+Siren+EDAR <font color=\"#FFFFFF\">+40%% Weapon Switch</font>   <font color=\"#FFD700\">Brute Force</font> Husk+Scrake+FP <font color=\"#FFFFFF\">+20%% All Damage</font>"
    UpgradeDescription(4)="<font color=\"#87CEEB\">Tier 3 (Boss+):</font> <font color=\"#FFD700\">King Slayer</font> Boss+FP <font color=\"#FFFFFF\">+50%% Dmg, +30%% Resist, Grab Immunity</font>   <font color=\"#FFD700\">Apex Predator</font> Boss+Scrake <font color=\"#FFFFFF\">+40%% Dmg, +30%% Speed, See Health</font>   <font color=\"#FFD700\">Trophy Wall</font> Boss+Trash <font color=\"#FFFFFF\">+30%% Dmg, +50%% Ammo, +30%% Reload</font>"
    UpgradeDescription(5)="<font color=\"#87CEEB\">Tier 4:</font> <font color=\"#FFD700\">Legendary Hunter</font> Boss+Boss <font color=\"#FFFFFF\">+75%% Dmg, +50%% Resist, +50%% Speed, Grab Immunity, See Health, +50 HP</font>"
    UpgradeDescription(6)="<font color=\"#CC8800\">Endless Hunt:</font> After <font color=\"#FFFFFF\">3</font> sets, trophies <font color=\"#FFD700\">stack infinitely</font> in <font color=\"#FFFFFF\">5</font> slots. Per stack: <font color=\"#87CEEB\">Clot</font> +1 Dosh/wave   <font color=\"#87CEEB\">Crawler</font> +1%% Speed   <font color=\"#87CEEB\">Gorefast</font> +1%% Melee   <font color=\"#87CEEB\">Stalker</font> +1%% Mag   <font color=\"#87CEEB\">Bloat</font> +1 HP   <font color=\"#87CEEB\">Husk</font> -1%% Taken   <font color=\"#87CEEB\">Siren</font> +5%% Ammo   <font color=\"#87CEEB\">EDAR</font> +10%% Headshot   <font color=\"#87CEEB\">Scrake</font> +5 Armor   <font color=\"#87CEEB\">FP</font> +10%% Dmg   <font color=\"#87CEEB\">Boss</font> ALL"
    UpgradeDescription(7)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Keen Eye</font> - Trophy <font color=\"#FFFFFF\">drop chance</font> is <font color=\"#87CEEB\">doubled</font>"
    UpgradeDescription(8)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">Trophy Master</font> - Fixed <font color=\"#FFFFFF\">5%%</font> trophy drop rate. All <font color=\"#87CEEB\">set bonuses doubled</font>. <font color=\"#FF6666\">+50 HP</font> on <font color=\"#FFD700\">Legendary Hunter</font> set"
    UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_0'
    UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_1'
    UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_2'
    UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_3'
    UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_4'
    UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
    UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'

	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Predator_Legacy_Rank_5'

    Name="Default__DKUpgrade_Perk_Predator"
}
