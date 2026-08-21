class ZTUpgrade_Skill_LuckySalvage_Helper extends Info transient;

var int KillCount;
var int KillsRequired;

function PostBeginPlay()
{
    super.PostBeginPlay();
    
    if (Owner == None)
        Destroy();
    else
    {
        KillCount = 0;
        KillsRequired = 100;
    }
}

function OnZedKilled(int SkillLevel)
{
    local float ChancePercent;
    local int RandomRoll;
    
    KillCount++;
    
    // Check if we've reached the kill threshold
    if (KillCount >= KillsRequired)
    {
        // Calculate chance based on skill level
        ChancePercent = (SkillLevel == 1) ? 1.0 : 2.0;
        
        // Roll for loot chance (1-100)
        RandomRoll = Rand(100) + 1;
        
        if (RandomRoll <= ChancePercent)
        {
            AttemptWeaponGrant(SkillLevel);
        }
        
        // Reset kill counter
        KillCount = 0;
    }
}

function AttemptWeaponGrant(int SkillLevel)
{
    local KFGameReplicationInfo KFGRI;
    local array<STraderItem> AvailableWeapons;
    local STraderItem SelectedWeapon;
    local class<KFWeapon> WeaponClass;
    local KFWeapon NewWeapon;
    local int i, RandomIndex;
    local float AmmoPercent;
    local KFPawn OwnerPawn;
    
    if (Owner == None || KFPlayerController(Owner.Owner) == None)
        return;
    
    OwnerPawn = KFPawn(Owner);
    if (OwnerPawn == None)
        return;
        
    KFGRI = KFGameReplicationInfo(Owner.WorldInfo.GRI);
    
    if (KFGRI == None)
        return;
    
    // Build list of available weapons (excluding sidearms, knife, welder, syringe)
    for (i = 0; i < KFGRI.TraderItems.SaleItems.Length; i++)
    {
        if (IsValidLootWeapon(KFGRI.TraderItems.SaleItems[i]))
        {
            AvailableWeapons.AddItem(KFGRI.TraderItems.SaleItems[i]);
        }
    }
    
    if (AvailableWeapons.Length == 0)
        return;
    
    // Select weapon based on skill level (deluxe has weighted selection toward higher tiers)
    if (SkillLevel == 1)
    {
        // Level 1: Pure random selection
        RandomIndex = Rand(AvailableWeapons.Length);
        SelectedWeapon = AvailableWeapons[RandomIndex];
    }
    else
    {
        // Level 2: Weighted selection favoring higher tier weapons
        SelectedWeapon = SelectWeightedWeapon(AvailableWeapons);
    }
    
    // Create the weapon
    WeaponClass = class<KFWeapon>(DynamicLoadObject(SelectedWeapon.WeaponDef.default.WeaponClassPath, class'Class'));
    if (WeaponClass == None)
        return;
    
    NewWeapon = Owner.Spawn(WeaponClass, Owner);
    if (NewWeapon == None)
        return;
    
    // Set weapon ammo based on skill level
    AmmoPercent = (SkillLevel == 1) ? 0.4 : 0.8; // Level 1: 40% ammo, Level 2: 80% ammo
    
    // Set ammo amounts
    NewWeapon.AmmoCount[0] = int(float(NewWeapon.MagazineCapacity[0]) * AmmoPercent);
    NewWeapon.SpareAmmoCount[0] = int(float(NewWeapon.default.InitialSpareMags[0] * NewWeapon.MagazineCapacity[0]) * AmmoPercent);
    
    if (NewWeapon.UsesSecondaryAmmo())
    {
        NewWeapon.AmmoCount[1] = int(float(NewWeapon.MagazineCapacity[1]) * AmmoPercent);
        NewWeapon.SpareAmmoCount[1] = int(float(NewWeapon.default.InitialSpareMags[1] * NewWeapon.MagazineCapacity[1]) * AmmoPercent);
    }
    
    // Give weapon to player
    NewWeapon.GiveTo(OwnerPawn);
    if (NewWeapon.Owner != OwnerPawn)
    {
        NewWeapon.Destroy();
        return;
    }
    
    NewWeapon.DroppedPickupClass = class'ZedternalReborn.WMDroppedPickup';
    
    // Play effects
    PlayLootEffects();
}

function bool IsValidLootWeapon(STraderItem Item)
{
    local string WeaponPath;
    
    WeaponPath = Item.WeaponDef.default.WeaponClassPath;
    
    // Exclude sidearms, knife, welder, syringe
    if (InStr(WeaponPath, "KFWeap_Pistol_9mm") != INDEX_NONE ||
        InStr(WeaponPath, "KFWeap_Knife") != INDEX_NONE ||
        InStr(WeaponPath, "KFWeap_Welder") != INDEX_NONE ||
        InStr(WeaponPath, "KFWeap_Healer_Syringe") != INDEX_NONE ||
        InStr(WeaponPath, "WMWeap_Pistol_9mm") != INDEX_NONE)
    {
        return False;
    }
    
    // Only include primary weapons (has reasonable price and weight)
    if (Item.WeaponDef.default.BuyPrice < 200 || Item.WeaponDef.default.EffectiveRange < 50.0)
    {
        return False;
    }
    
    return True;
}

function STraderItem SelectWeightedWeapon(array<STraderItem> Weapons)
{
    local int i, TotalWeight, WeightedRoll, CurrentWeight;
    local int WeaponWeight;
    
    // Calculate total weight (higher tier = higher weight)
    TotalWeight = 0;
    for (i = 0; i < Weapons.Length; i++)
    {
        WeaponWeight = GetWeaponWeight(Weapons[i]);
        TotalWeight += WeaponWeight;
    }
    
    // Roll within total weight
    WeightedRoll = Rand(TotalWeight);
    
    // Find selected weapon
    CurrentWeight = 0;
    for (i = 0; i < Weapons.Length; i++)
    {
        CurrentWeight += GetWeaponWeight(Weapons[i]);
        if (WeightedRoll < CurrentWeight)
        {
            return Weapons[i];
        }
    }
    
    // Fallback to last weapon
    return Weapons[Weapons.Length - 1];
}

function int GetWeaponWeight(STraderItem Item)
{
    local int Price;
    
    Price = Item.WeaponDef.default.BuyPrice;
    
    // Weight based on price tiers
    if (Price >= 2000)
        return 5; // High-tier weapons (5x more likely than low-tier)
    else if (Price >= 1000)
        return 3; // Mid-tier weapons
    else
        return 1; // Low-tier weapons
}

reliable client function PlayLootEffects()
{
    local PlayerController PC;
    local KFPawn KFP;
    
    PC = GetALocalPlayerController();
    
    if (PC == None || Owner == None)
        return;
    
    KFP = KFPawn(Owner);
    if (KFP == None)
        return;
}

simulated function DrawOnHUD(Canvas C)
{
    local float ProgressPercent;
    local string DisplayText;
    local float XPos, YPos, TextWidth, TextHeight;
    
    if (Owner == None || KFPlayerController(Owner.Owner) == None)
        return;
    
    ProgressPercent = float(KillCount) / float(KillsRequired);
    DisplayText = "Lucky Salvage: " $ KillCount $ "/" $ KillsRequired $ " (" $ int(ProgressPercent * 100) $ "%)";
    
    // Position near bottom right of screen
    C.Font = class'Engine'.static.GetSmallFont();
    C.StrLen(DisplayText, TextWidth, TextHeight);
    
    XPos = C.SizeX - TextWidth - 20;
    YPos = C.SizeY - TextHeight - 60; // Above weapon HUD
    
    // Draw background
    C.SetDrawColor(0, 0, 0, 128);
    C.SetPos(XPos - 5, YPos - 2);
    C.DrawRect(TextWidth + 10, TextHeight + 4);
    
    // Draw progress bar
    C.SetDrawColor(64, 64, 64, 255);
    C.SetPos(XPos - 5, YPos + TextHeight + 2);
    C.DrawRect(TextWidth + 10, 4);
    
    C.SetDrawColor(0, 255, 0, 255);
    C.SetPos(XPos - 5, YPos + TextHeight + 2);
    C.DrawRect((TextWidth + 10) * ProgressPercent, 4);
    
    // Draw text
    C.SetDrawColor(255, 255, 255, 255);
    C.SetPos(XPos, YPos);
    C.DrawText(DisplayText);
}

defaultproperties
{
    bOnlyRelevantToOwner=True
    
    KillCount=0
    KillsRequired=100
    
    Name="Default__ZTUpgrade_Skill_LuckySalvage_Helper"
}