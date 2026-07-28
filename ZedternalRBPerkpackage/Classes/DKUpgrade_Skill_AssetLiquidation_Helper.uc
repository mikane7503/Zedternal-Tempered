class DKUpgrade_Skill_AssetLiquidation_Helper extends Info
    transient;

struct WeaponInstanceRecord
{
    var KFWeapon WeaponInstance;      // Actual weapon reference, not class
    var int TotalDamage;              // Damage dealt with this specific weapon
};

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var array<WeaponInstanceRecord> TrackedWeapons;
var array<KFWeapon> LastKnownInventory;
var float WeaponCheckInterval;
var bool bInTraderRange;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        TrackedWeapons.Length = 0;
        SetTimer(WeaponCheckInterval, True);
        UpdateCurrentInventory();
    }
}

function Timer()
{
    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }
    
    // Check trader proximity and weapon changes
    CheckTraderAndInventory();
}

function TrackWeaponDamage(KFWeapon Weapon, int Damage)
{
    local int i;
    local WeaponInstanceRecord NewRecord;
    
    if (Weapon == None || Damage <= 0) return;
    
    // Only track damage for weapons currently owned by this player
    if (Weapon.Owner != Player) return;
    
    // Find existing record for this specific weapon instance
    for (i = 0; i < TrackedWeapons.Length; i++)
    {
        if (TrackedWeapons[i].WeaponInstance == Weapon)
        {
            TrackedWeapons[i].TotalDamage += Damage;
            return;
        }
    }
    
    // Create new record for this weapon instance
    NewRecord.WeaponInstance = Weapon;
    NewRecord.TotalDamage = Damage;
    TrackedWeapons.AddItem(NewRecord);
}

function CheckTraderAndInventory()
{
    local bool bCurrentlyInTrader;
    
    bCurrentlyInTrader = IsNearTrader();
    
    // Only process sales when entering trader area (prevents drop exploits)
    if (!bInTraderRange && bCurrentlyInTrader)
    {
        // Just entered trader - update inventory baseline
        UpdateCurrentInventory();
    }
    else if (bInTraderRange && !bCurrentlyInTrader)
    {
        // Left trader - check for sold weapons
        CheckForSoldWeapons();
        UpdateCurrentInventory();
    }
    
    bInTraderRange = bCurrentlyInTrader;
}

function UpdateCurrentInventory()
{
    local KFWeapon Weapon;
    
    LastKnownInventory.Length = 0;
    foreach Player.InvManager.InventoryActors(class'KFWeapon', Weapon)
    {
        LastKnownInventory.AddItem(Weapon);
    }
}

function CheckForSoldWeapons()
{
    local array<KFWeapon> CurrentInventory;
    local KFWeapon Weapon;
    local int i, j;
    local bool bWeaponStillPresent;
    
    // Get current inventory
    CurrentInventory.Length = 0;
    foreach Player.InvManager.InventoryActors(class'KFWeapon', Weapon)
    {
        CurrentInventory.AddItem(Weapon);
    }
    
    // Check if any previous weapons are missing (sold in trader)
    for (i = 0; i < LastKnownInventory.Length; i++)
    {
        bWeaponStillPresent = false;
        for (j = 0; j < CurrentInventory.Length; j++)
        {
            if (LastKnownInventory[i] == CurrentInventory[j])
            {
                bWeaponStillPresent = true;
                break;
            }
        }
        
        // Weapon was sold (missing from inventory while in trader)
        if (!bWeaponStillPresent)
        {
            PayLiquidationBonus(LastKnownInventory[i]);
        }
    }
}

function PayLiquidationBonus(KFWeapon SoldWeapon)
{
    local int i;
    local int DamageDealt, BonusDosh;
    local float DamagePercent;
    local KFPlayerController KFPC;
    local KFPlayerReplicationInfo KFPRI;
    
    if (SoldWeapon == None) return;
    
    // Find damage record for this specific weapon instance
    for (i = 0; i < TrackedWeapons.Length; i++)
    {
        if (TrackedWeapons[i].WeaponInstance == SoldWeapon)
        {
            DamageDealt = TrackedWeapons[i].TotalDamage;
            // Remove the record since weapon is sold
            TrackedWeapons.Remove(i, 1);
            break;
        }
    }
    
    if (DamageDealt <= 0) return; // No damage dealt with this weapon
    
    // Calculate bonus based on damage percentage
    DamagePercent = class'DKUpgrade_Skill_AssetLiquidation'.default.DamagePercentage[UpgradeLevel - 1];
    BonusDosh = int(float(DamageDealt) * DamagePercent);
    
    if (BonusDosh >= 1)
    {
        KFPC = KFPlayerController(Player.Controller);
        if (KFPC != None)
        {
            KFPRI = KFPlayerReplicationInfo(KFPC.PlayerReplicationInfo);
            if (KFPRI != None)
            {
                KFPRI.AddDosh(BonusDosh);
                class'DKMessageManager'.static.SendImportant(KFPC, "ASSET LIQUIDATION: +" $ BonusDosh $ " Dosh from " $ DamageDealt $ " damage with " $ GetWeaponName(SoldWeapon.Class));
            }
        }
    }
}

function bool IsNearTrader()
{
    local KFTraderTrigger Trader;
    local float DistanceSq;
    
    // Find nearest trader
    foreach Player.WorldInfo.DynamicActors(class'KFTraderTrigger', Trader)
    {
        DistanceSq = VSizeSQ(Player.Location - Trader.Location);
        if (DistanceSq <= Square(500.0f)) // Trader proximity range
        {
            return true;
        }
    }
    
    return false;
}

function string GetWeaponName(class<KFWeapon> WeaponClass)
{
    local string WeaponName;
    
    WeaponName = string(WeaponClass);
    
    // Extract weapon name from class path
    if (InStr(WeaponName, "KFWeap_") != -1)
    {
        WeaponName = Mid(WeaponName, InStr(WeaponName, "KFWeap_") + 7);
    }
    
    return WeaponName;
}

// Clean up dead weapon references and reset for new wave
function WaveEnd()
{
    local int i;
    
    // Remove any dead weapon references
    for (i = TrackedWeapons.Length - 1; i >= 0; i--)
    {
        if (TrackedWeapons[i].WeaponInstance == None)
        {
            TrackedWeapons.Remove(i, 1);
        }
        else
        {
            // Reset damage for next wave
            TrackedWeapons[i].TotalDamage = 0;
        }
    }
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    WeaponCheckInterval=0.5f
    bInTraderRange=False

    Name="Default__DKUpgrade_Skill_AssetLiquidation_Helper"
}