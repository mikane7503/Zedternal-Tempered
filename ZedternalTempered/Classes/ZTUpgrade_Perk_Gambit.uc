// ===================================================================
// ZTUpgrade_Perk_Gambit - "The High Roller"
//
// No passive bonuses. Each wave, a random Gambit challenge is rolled.
// Completing the Gambit grants a permanent reward ? one random stat
// is picked from: Damage, Dosh, Speed, Reload Speed, Recoil,
// Magazine Size, or Spare Ammo.
// Failing has no penalty ? the gambit simply expires at wave end.
//
// Rank 1-9:   Normal Gambits only
// Rank 10-19: Normal + Rare Gambits (1% Mythic chance)
// Rank 20:    Normal + Rare + Legendary Gambits (1% Mythic chance)
//
// Rewards scale with perk level ? higher level = better payoff.
//
// MUTUALLY EXCLUSIVE with Shapeshifter (shares HUD region).
// ===================================================================
class ZTUpgrade_Perk_Gambit extends ZTUpgrade_Perk;

// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Gambit_Helper H;
    local bool bFound;

    if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
    {
        bFound = False;
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Gambit_Helper', H)
        {
            bFound = True;
            H.SetPerkLevel(upgLevel);
            break;
        }

        if (!bFound)
        {
            H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Gambit_Helper', OwnerPawn);
            H.SetPerkLevel(upgLevel);
        }
    }
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Gambit_Helper H;
    local KFPlayerController KFPC;
    local ZTHudWrapper HUD;

    if (OwnerPawn != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Gambit_Helper', H)
        {
            H.Destroy();
        }

        // Clear Gambit display from HUD wrapper
        KFPC = KFPlayerController(OwnerPawn.GetALocalPlayerController());
        if (KFPC != None && KFPC.myHUD != None)
        {
            HUD = ZTHudWrapper(KFPC.myHUD);
            if (HUD != None)
                HUD.ClearGambitDisplay();
        }
    }
}

// GetHelper spawns if missing (for server-side calls)
static function ZTUpgrade_Perk_Gambit_Helper GetHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Gambit_Helper H;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Gambit_Helper', H)
        {
            return H;
        }

        H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Gambit_Helper', OwnerPawn);
    }

    return H;
}

// FindHelper does NOT spawn ? safe for client-side simulated functions
static simulated function ZTUpgrade_Perk_Gambit_Helper FindHelper(Pawn OwnerPawn)
{
    local ZTUpgrade_Perk_Gambit_Helper H;

    if (KFPawn_Human(OwnerPawn) != None)
    {
        foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Gambit_Helper', H)
        {
            return H;
        }
    }

    return None;
}

// ===================================================================
// DAMAGE GIVEN ? Kill tracking + apply accumulated damage bonus
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
    optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
    optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
    optional int HitZoneIdx, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Gambit_Helper H;

    if (DamageInstigator == None || DamageInstigator.Pawn == None)
        return;

    H = GetHelper(DamageInstigator.Pawn);
    if (H == None)
        return;

    // Apply accumulated permanent damage bonus
    if (H.AccumulatedDamage > 0.0f)
        InDamage += Round(float(DefaultDamage) * H.AccumulatedDamage);

    // Track this hit for gambit progress (server-side)
    // NOTE: Do NOT check IsAliveAndWell() here ? deferred verification
    // handles dead-zed filtering. Checking it here drops hits on dying
    // zeds that haven't had Health set to 0 yet (e.g. overkill damage).
    if (MyKFPM != None && H.bGambitActive)
        H.OnDamageDealt(MyKFPM, InDamage, HitZoneIdx, MyKFW);
}

// ===================================================================
// DAMAGE TAKEN ? Track for Iron Skin / Untouchable / Flawless
// ===================================================================

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel,
    KFPawn OwnerPawn, optional class<DamageType> DamageType,
    optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
    local ZTUpgrade_Perk_Gambit_Helper H;

    if (OwnerPawn == None || InDamage <= 0)
        return;

    H = GetHelper(OwnerPawn);
    if (H != None && H.bGambitActive)
        H.OnDamageTaken(InDamage);
}

// ===================================================================
// SPEED ? Apply accumulated permanent speed bonus (client-side)
// ===================================================================

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Gambit_Helper H;

    if (OwnerPawn == None)
        return;

    H = FindHelper(OwnerPawn);
    if (H != None && H.AccumulatedSpeed > 0.0f)
        InSpeed += DefaultSpeed * H.AccumulatedSpeed;
}

// ===================================================================
// RELOAD RATE ? Track reloads (server) + apply bonus (client)
// ===================================================================

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
    local ZTUpgrade_Perk_Gambit_Helper H;

    if (OwnerPawn == None)
        return;

    // Server: track reload events for gambit conditions
    if (OwnerPawn.Role == Role_Authority)
    {
        H = GetHelper(OwnerPawn);
        if (H != None && H.bGambitActive)
            H.OnReload();
    }
    else
    {
        H = FindHelper(OwnerPawn);
    }

    // Client + Server: apply accumulated reload speed bonus
    if (H != None && H.AccumulatedReload > 0.0f)
        InReloadRateScale = 1.f / (1.f / InReloadRateScale + H.AccumulatedReload);
}

// ===================================================================
// RECOIL ? Apply accumulated recoil reduction (client-side)
// ===================================================================

static simulated function ModifyRecoil(out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
    local ZTUpgrade_Perk_Gambit_Helper H;
    local KFPawn OwnerPawn;

    if (KFW == None)
        return;

    OwnerPawn = KFPawn(KFW.Instigator);
    if (OwnerPawn == None)
        return;

    H = FindHelper(OwnerPawn);
    if (H != None && H.AccumulatedRecoil > 0.0f)
        InRecoilModifier -= DefaultRecoilModifier * H.AccumulatedRecoil;
}

// ===================================================================
// MAG SIZE ? Apply accumulated magazine size bonus (client-side)
// ===================================================================

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=false, optional name WeaponClassname)
{
    local ZTUpgrade_Perk_Gambit_Helper H;
    local KFPawn OwnerPawn;

    if (KFW == None)
        return;

    OwnerPawn = KFPawn(KFW.Instigator);
    if (OwnerPawn == None)
        return;

    H = FindHelper(OwnerPawn);
    if (H != None && H.AccumulatedMagSize > 0.0f)
        InMagazineCapacity += Round(float(DefaultMagazineCapacity) * H.AccumulatedMagSize);
}

// ===================================================================
// SPARE AMMO ? Apply accumulated spare ammo bonus (client-side)
// ===================================================================

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=false)
{
    local ZTUpgrade_Perk_Gambit_Helper H;
    local KFPawn OwnerPawn;

    if (bSecondary)
        return;

    if (KFW == None)
        return;

    OwnerPawn = KFPawn(KFW.Instigator);
    if (OwnerPawn == None)
        return;

    H = FindHelper(OwnerPawn);
    if (H != None && H.AccumulatedSpareAmmo > 0.0f)
        InSpareAmmo += Round(float(DefaultSpareAmmo) * H.AccumulatedSpareAmmo);
}

// ===================================================================
// WAVE END ? Evaluate gambit, give rewards, roll next
// ===================================================================

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
    local ZTUpgrade_Perk_Gambit_Helper H;

    if (KFPC == None || KFPC.Pawn == None)
        return;

    H = GetHelper(KFPC.Pawn);
    if (H != None)
    {
        H.SetPerkLevel(upgLevel);
        H.OnWaveEnd(KFPC);
    }
}

// ===================================================================
// HUD ? Draw gambit display (client-side)
// ===================================================================

// HUD rendering is handled by ZTHudWrapper.DrawGambitDisplay().
// Helper pushes display data via PushToHUD() -> UpdateGambitDisplay().
static simulated function DrawOnHUD(int upgLevel, Canvas C, KFPawn OwnerPawn)
{
    // Intentionally empty ? ZTHudWrapper handles all Gambit HUD rendering
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Gambit_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_Gambit]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_Gambit"
    LocalizeDescriptionLineCount=4

    UpgradeName="Gambit"
    upgradeDescription(0)="Each wave, a random <font color=\"#15d7fa\">Gambit Challenge</font> is rolled. Complete it for a <font color=\"#77d914\">permanent stat bonus</font>."
    upgradeDescription(1)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#15d7fa\">Rare</font> gambits unlock with greater rewards. <font color=\"#ffc832\">Mythic</font> gambits have a <font color=\"#77d914\">1%</font> roll chance."
    upgradeDescription(2)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#b850ff\">Legendary</font> gambits unlock for the highest payouts."
    upgradeDescription(3)="Rewards scale with <font color=\"#77d914\">Perk Level</font> and include Damage, Dosh, Speed, Reload, Recoil, Mag Size, or Spare Ammo."

	// Legacy (hand-made) artwork icons

    Name="Default__ZTUpgrade_Perk_Gambit"
}
