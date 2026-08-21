// ===================================================================
// ZTUpgrade_Perk_MissingNO - "The Living Glitch"
// Theme: Corrupted memory address, item duplication, type confusion
// Color: Magenta + Cyan + Glitch-Green (RGB: 255,0,255 / 0,255,255 / 0,255,0)
//
// Mechanics:
//   Passive 1 (1-20): +2% spare ammo and mag size per level (item dup echo)
//   Passive 2 (1-20): Each hit has 1.5% per level chance for a GLITCH proc
//                     (one of: +50% damage, +1 dosh, ammo refund, HP regen)
//   Lv 10 - Type Mismatch: Random elemental DoT type each wave
//                          (rotates: Inferno / BlackIce / ToxicOverload /
//                           Thermite / Hypothermia)
//   Lv 20 - DATA MISSING: 25% survive proc on fatal damage (full heal,
//                         4s invuln, +100% speed, once per wave) +
//                         10% chance to duplicate a primary weapon at
//                         wave end as a dropped pickup at player's feet
// ===================================================================
class ZTUpgrade_Perk_MissingNO extends ZTUpgrade_Perk config(ZedternalUnlimited_Balance);

// ===================================================================
// CONFIG VARIABLES
// ===================================================================

// Passive scaling
var config float SpareAmmoPerLevel;       // +2% spare ammo per level
var config float MagSizePerLevel;         // +2% mag size per level

// GLITCH proc
var config float GlitchProcChancePerLevel; // 1.5% per level (max 30% at Lv 20)
var config float GlitchDamageBonus;        // +50% damage on damage proc
var config int   GlitchDoshAmount;         // +1 dosh on dosh proc
var config float GlitchAmmoRefillFraction; // 5% of mag refilled on ammo proc
var config int   GlitchHealAmount;         // +1 HP on heal proc

// Lv 10 - Type Mismatch
var config float TypeMismatchDamageScale;  // 20% of base damage as DoT element

// Lv 20 - DATA MISSING (survive proc)
var config float DataMissingProcChance;        // 25% chance on fatal hit
var config float DataMissingInvulnDuration;    // 4 seconds
var config float DataMissingSpeedMultiplier;   // +100% speed (additive to default)

// Lv 20 - Item Duplication (wave end)
var config float WaveEndDuplicateChance;       // 10% chance per wave end

var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.SpareAmmoPerLevel = 0.02f;
		default.MagSizePerLevel = 0.02f;

		default.GlitchProcChancePerLevel = 0.015f;
		default.GlitchDamageBonus = 0.50f;
		default.GlitchDoshAmount = 1;
		default.GlitchAmmoRefillFraction = 0.05f;
		default.GlitchHealAmount = 1;

		default.TypeMismatchDamageScale = 0.20f;

		default.DataMissingProcChance = 0.25f;
		default.DataMissingInvulnDuration = 4.0f;
		default.DataMissingSpeedMultiplier = 1.0f;

		default.WaveEndDuplicateChance = 0.10f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

// ===================================================================
// HELPER MANAGEMENT
// ===================================================================

static function ZTUpgrade_Perk_MissingNO_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_MissingNO_Helper Helper;

	if (OwnerPawn == None)
		return None;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_MissingNO_Helper', Helper)
		return Helper;

	return None;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_MissingNO_Helper Helper;

	if (KFPawn_Human(OwnerPawn) == None)
		return;

	if (OwnerPawn.Role != ROLE_Authority)
		return;

	// Existing helper - update level
	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_MissingNO_Helper', Helper)
	{
		Helper.SetUpgradeLevel(upgLevel);
		return;
	}

	// Spawn new helper
	Helper = OwnerPawn.Spawn(class'ZTUpgrade_Perk_MissingNO_Helper', OwnerPawn);
	if (Helper != None)
	{
		Helper.SetUpgradeLevel(upgLevel);
		`log("MissingNO: Spawned helper for" @ OwnerPawn.PlayerReplicationInfo.PlayerName);
	}
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_MissingNO_Helper Helper;

	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_MissingNO_Helper', Helper)
		{
			Helper.Cleanup();
			Helper.Destroy();
		}
	}
}

// ===================================================================
// PASSIVE 1 - Item Duplication Echo (Spare Ammo + Mag Size)
// ===================================================================

static simulated function ModifySpareAmmoAmount(out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=False)
{
	InSpareAmmo += Round(float(DefaultSpareAmmo) * default.SpareAmmoPerLevel * upgLevel);
}

static simulated function ModifyMagSizeAndNumber(out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=False, optional name WeaponClassname)
{
	InMagazineCapacity += Round(float(DefaultMagazineCapacity) * default.MagSizePerLevel * upgLevel);
}

// ===================================================================
// PASSIVE 2 - GLITCH Proc + LV 10 Type Mismatch
// ===================================================================

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_MissingNO_Helper Helper;
	local class<KFDamageType> RotatingDT;
	local int GlitchType, RefillAmt;

	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;

	// ---- Re-entry guard: skip processing if this is one of our rotating DTs ----
	// Prevents infinite DoT cascade and stops GLITCH procs from rolling on
	// our own DoT ticks.
	if (DamageType != None && IsRotatingDamageType(DamageType))
		return;

	Helper = GetHelper(DamageInstigator.Pawn);

	// ---- GLITCH PROC ----
	// Skill: Stack Corruption adds a flat chance bonus via the helper.
	if (FRand() < default.GlitchProcChancePerLevel * upgLevel
		+ ((Helper != None) ? Helper.SkillGlitchChanceBonus : 0.0f))
	{
		// Skill: Hex Edit unlocks a 5th outcome (armor).
		GlitchType = Rand((Helper != None && Helper.SkillArmorProcLevel > 0) ? 5 : 4);
		switch (GlitchType)
		{
			case 0: // Bonus damage
				InDamage += Round(float(DefaultDamage) * default.GlitchDamageBonus);
				break;

			case 1: // Free dosh
				if (DamageInstigator.PlayerReplicationInfo != None)
					KFPlayerReplicationInfo(DamageInstigator.PlayerReplicationInfo).AddDosh(default.GlitchDoshAmount);
				break;

			case 2: // Ammo refund
				if (MyKFW != None && MyKFW.MagazineCapacity[0] > 0)
				{
					RefillAmt = Round(float(MyKFW.MagazineCapacity[0]) * default.GlitchAmmoRefillFraction);
					if (RefillAmt < 1)
						RefillAmt = 1;
					MyKFW.AmmoCount[0] = Min(MyKFW.MagazineCapacity[0], MyKFW.AmmoCount[0] + RefillAmt);
				}
				break;

			case 3: // HP regen
				if (DamageInstigator.Pawn.Health < DamageInstigator.Pawn.HealthMax)
					DamageInstigator.Pawn.HealDamage(default.GlitchHealAmount, DamageInstigator, class'KFDT_Healing');
				break;

			case 4: // Armor (Skill: Hex Edit)
				if (KFPawn_Human(DamageInstigator.Pawn) != None)
				{
					KFPawn_Human(DamageInstigator.Pawn).Armor = Min(KFPawn_Human(DamageInstigator.Pawn).MaxArmor,
						KFPawn_Human(DamageInstigator.Pawn).Armor + ((Helper.SkillArmorProcLevel >= 2) ? 10 : 5));
				}
				break;
		}
	}

	// ---- LV 10: TYPE MISMATCH ----
	if (upgLevel >= 10 && MyKFPM != None)
	{
		Helper = GetHelper(DamageInstigator.Pawn);
		if (Helper != None && Helper.CurrentDamageTypeIndex >= 0)
		{
			RotatingDT = GetRotatingDT(Helper.CurrentDamageTypeIndex);
			if (RotatingDT != None)
			{
				MyKFPM.ApplyDamageOverTime(
					Round(float(DefaultDamage) * default.TypeMismatchDamageScale),
					DamageInstigator,
					RotatingDT
				);
			}
		}
	}
}

// Returns the rotating elemental damage type for the given index (0-4).
// Index < 0 or out of range returns None (Lv 10 not active).
static function class<KFDamageType> GetRotatingDT(int Index)
{
	switch (Index)
	{
		case 0: return class'ZTDT_InfernoRounds';
		case 1: return class'ZTDT_BlackIce';
		case 2: return class'ZTDT_ToxicOverload';
		case 3: return class'ZTDT_Thermite';
		case 4: return class'ZTDT_Hypothermia';
	}
	return None;
}

// Returns true if the given damage type is one of MissingNO's rotating
// elements. Used as a re-entry guard in ModifyDamageGiven.
static function bool IsRotatingDamageType(class<KFDamageType> DT)
{
	return DT == class'ZTDT_InfernoRounds'
		|| DT == class'ZTDT_BlackIce'
		|| DT == class'ZTDT_ToxicOverload'
		|| DT == class'ZTDT_Thermite'
		|| DT == class'ZTDT_Hypothermia';
}

// ===================================================================
// LV 20 - DATA MISSING: Fatal damage survive proc + invuln window
// ===================================================================

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_MissingNO_Helper Helper;

	if (OwnerPawn == None)
		return;

	Helper = GetHelper(OwnerPawn);
	if (Helper == None)
		return;

	// Glitch active: full damage block during the 4s invuln window.
	if (Helper.bGlitchActive)
	{
		InDamage = 0;
		return;
	}

	// Fatal damage trigger: only at Lv 20, only once per wave.
	if (upgLevel >= 20 && !Helper.bDataMissingUsedThisWave
		&& (OwnerPawn.Health - InDamage) <= 0
		&& FRand() < default.DataMissingProcChance + Helper.SkillDataMissingChanceBonus)
	{
		Helper.ActivateDataMissing(KFPawn_Human(OwnerPawn), default.DataMissingInvulnDuration);
		InDamage = 0;
	}
}

// ===================================================================
// LV 20 - 2x Speed during DATA MISSING window
// ===================================================================

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_MissingNO_Helper Helper;

	if (OwnerPawn == None)
		return;

	Helper = GetHelper(OwnerPawn);
	if (Helper != None && Helper.bGlitchActive)
		InSpeed += DefaultSpeed * default.DataMissingSpeedMultiplier;
}

// ===================================================================
// WAVE END - Reset survive proc, roll new DT for Lv 10, roll duplicate for Lv 20
// ===================================================================

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_MissingNO_Helper Helper;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	Helper = GetHelper(KFPC.Pawn);
	if (Helper == None)
		return;

	Helper.SetUpgradeLevel(upgLevel);
	Helper.OnWaveEnd();
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_MissingNO_Rank_0'
	// --- Localization ---
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Perk_MissingNO"
	LocalizeDescriptionLineCount=5

	// --- Display ---
	UpgradeName="MissingNO"

	UpgradeDescription(0)="<font color=\"#FF00FF\">Memory Bleed:</font> All weapons gain <font color=\"#00FF00\">+%x%%</font> <font color=\"#00FFFF\">Spare Ammo</font>"
	UpgradeDescription(1)="<font color=\"#FF00FF\">Echo Magazine:</font> All weapons gain <font color=\"#00FF00\">+%x%%</font> <font color=\"#00FFFF\">Magazine Size</font>"
	UpgradeDescription(2)="<font color=\"#FF00FF\">Glitch Proc:</font> Each hit has <font color=\"#00FF00\">~%x%%</font> chance for a random effect: <font color=\"#00FFFF\">bonus damage</font>, <font color=\"#00FFFF\">free dosh</font>, <font color=\"#00FFFF\">ammo refund</font>, or <font color=\"#00FFFF\">HP regen</font>"
	UpgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> <font color=\"#FFD700\">Type Mismatch</font> - Your weapons gain a <font color=\"#00FFFF\">random elemental damage type</font> each wave (Fire / Cryo / Toxic / Burn / Slow)"
	UpgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> <font color=\"#FFD700\">DATA MISSING</font> - Fatal damage has <font color=\"#00FF00\">25%</font> chance to <font color=\"#00FFFF\">glitch out</font> (full heal, invuln, +100% speed for 4s). At wave end, <font color=\"#00FF00\">10%</font> chance to <font color=\"#00FFFF\">duplicate</font> a random primary weapon. <font color=\"#666666\">Once per wave.</font>"

	// PerkBonus values for UI display (note: incValue is int per WMUpgrade_Perk).
	// Glitch proc displays ~2%/lvl which is close to the actual 1.5%/lvl config.
	PerkBonus(0)=(baseValue=0, incValue=2, maxValue=-1)    // Spare ammo %
	PerkBonus(1)=(baseValue=0, incValue=2, maxValue=-1)    // Mag size %
	PerkBonus(2)=(baseValue=0, incValue=2, maxValue=30)    // Glitch chance % (approx)

	// --- Icons (21 ranks: 0-20) ---

	// --- Legacy (hand-made) artwork - empty until art is created ---

	Name="Default__ZTUpgrade_Perk_MissingNO"
}
