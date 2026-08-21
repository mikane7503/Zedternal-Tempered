// ===================================================================
// ZTUpgrade_Perk_MissingNO_Helper - State tracker for MissingNO perk
//
// Tracks:
//   - bDataMissingUsedThisWave   - once-per-wave gate for survive proc
//   - bGlitchActive              - 4s invuln window after survive trigger
//   - CurrentDamageTypeIndex     - rotating elemental DT for Lv 10 (-1 = inactive)
//   - UpgradeLevel               - cached perk level for Lv 10/20 gating
//
// Triggers:
//   - ActivateDataMissing()      - called by perk's ModifyDamageTaken on fatal hit
//   - OnWaveEnd()                - called by perk's WaveEnd hook; resets state,
//                                  re-rolls DT for Lv 10, rolls 10% duplicate for Lv 20
//
// Sounds (registered in ZTSoundManager.RegisterDefaultSounds, played via
//        ZTPlayerController.ClientPlayBuffSound per SoundImplementationGuide.md):
//   - MissingNO_DataMissing      - on fatal-hit survive proc
//   - MissingNO_Duplicate        - on successful wave-end weapon duplication
//   - MissingNO_TypeRoll         - on each new elemental rotation roll (Lv 10+)
// ===================================================================
class ZTUpgrade_Perk_MissingNO_Helper extends Info transient;

// Cached perk level (updated via SetUpgradeLevel)
var int UpgradeLevel;

// DATA MISSING (Lv 20 survive proc) state
var bool bGlitchActive;
var bool bDataMissingUsedThisWave;

// --- Skill overrides (set by ZTUpgrade_Skill_* via setters; Possess pattern) ---
var float SkillGlitchChanceBonus;      // Stack Corruption (flat add to proc chance)
var int SkillArmorProcLevel;           // Hex Edit (0 off, 1: +5 armor outcome, 2: +10)
var float SkillDataMissingChanceBonus; // Corrupted Save (flat add)
var int SkillDataMissingMaxUses;       // Corrupted Save Deluxe (2 uses/wave)
var int DataMissingUsesThisWave;

// Type Mismatch (Lv 10) - index into the rotating DT pool (0-4), or -1 if inactive
var int CurrentDamageTypeIndex;

// Number of rotating damage types in the pool (matches ZTUpgrade_Perk_MissingNO.GetRotatingDT)
var const int ROTATING_DT_COUNT;

// ===================================================================
// LIFECYCLE
// ===================================================================

function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Owner == None)
	{
		Destroy();
		return;
	}

	bGlitchActive = false;
	bDataMissingUsedThisWave = false;
	CurrentDamageTypeIndex = -1;

	`log("MissingNO Helper: Initialized for" @ KFPawn(Owner).PlayerReplicationInfo.PlayerName);
}

// ===================================================================
// LEVEL TRACKING
// ===================================================================

function SetUpgradeLevel(int NewLevel)
{
	local bool bWasBelowTen;

	bWasBelowTen = (UpgradeLevel < 10);
	UpgradeLevel = NewLevel;

	// Just crossed into Lv 10 territory - roll initial DT immediately so
	// players get the Type Mismatch effect on their first wave at Lv 10.
	if (bWasBelowTen && UpgradeLevel >= 10 && CurrentDamageTypeIndex < 0)
		RollDamageType();

	// Dropped below Lv 10 (e.g. perk reroll) - clear DT
	if (UpgradeLevel < 10)
		CurrentDamageTypeIndex = -1;
}

// --- Skill setters (0 level = revert to neutral) ---
function SetSkillGlitchBonus(float Bonus) { SkillGlitchChanceBonus = FMax(0.0f, Bonus); }
function SetSkillArmorProc(int L) { SkillArmorProcLevel = Clamp(L, 0, 2); }
function SetSkillDataMissing(float ChanceBonus, int MaxUses)
{
	SkillDataMissingChanceBonus = FMax(0.0f, ChanceBonus);
	SkillDataMissingMaxUses = Max(1, MaxUses);
}

// ===================================================================
// TYPE MISMATCH (Lv 10) - Random elemental rotation per wave
// ===================================================================

function RollDamageType()
{
	CurrentDamageTypeIndex = Rand(default.ROTATING_DT_COUNT);
	`log("MissingNO Helper: Rolled new damage type index =" @ CurrentDamageTypeIndex);

	NotifyTypeMismatchRolled();
}

function NotifyTypeMismatchRolled()
{
	local KFPlayerController KFPC;
	local string TypeName;

	if (Owner == None)
		return;

	KFPC = KFPlayerController(KFPawn(Owner).Controller);
	if (KFPC == None)
		return;

	switch (CurrentDamageTypeIndex)
	{
		case 0: TypeName = "INFERNO"; break;
		case 1: TypeName = "BLACK ICE"; break;
		case 2: TypeName = "TOXIC"; break;
		case 3: TypeName = "THERMITE"; break;
		case 4: TypeName = "HYPOTHERMIA"; break;
		default: TypeName = "UNKNOWN"; break;
	}

	class'ZTMessageManager'.static.SendImportant(
		KFPC,
		"TYPE GLITCH: Weapons now infused with " $ TypeName
	);

	PlayMissingNOSound('MissingNO_TypeRoll');
}

// ===================================================================
// DATA MISSING (Lv 20) - Fatal damage survive proc
// ===================================================================

function ActivateDataMissing(KFPawn_Human Player, float Duration)
{
	local int HealAmount;
	local KFPlayerController KFPC;

	if (Player == None || !Player.IsAliveAndWell())
		return;

	bGlitchActive = true;
	++DataMissingUsesThisWave;
	bDataMissingUsedThisWave = (DataMissingUsesThisWave >= Max(1, SkillDataMissingMaxUses));

	// Heal to full via the proper damage pipeline so it replicates.
	HealAmount = Player.HealthMax - Player.Health;
	if (HealAmount > 0)
	{
		KFPC = KFPlayerController(Player.Controller);
		Player.HealDamage(HealAmount, KFPC, class'KFDT_Healing');
	}

	ClearTimer(NameOf(DeactivateDataMissing));
	SetTimer(Duration, false, NameOf(DeactivateDataMissing));

	// Notify
	KFPC = KFPlayerController(Player.Controller);
	if (KFPC != None)
	{
		class'ZTMessageManager'.static.SendCritical(
			KFPC,
			"DATA MISSING - Execution corrupted! Invulnerable for " $ string(int(Duration)) $ "s"
		);
	}

	PlayMissingNOSound('MissingNO_DataMissing');

	`log("MissingNO Helper: DATA MISSING activated for" @ Duration @ "seconds");
}

function DeactivateDataMissing()
{
	bGlitchActive = false;

	if (Owner == None)
	{
		Destroy();
		return;
	}

	`log("MissingNO Helper: DATA MISSING expired");
}

// ===================================================================
// WAVE END - Reset state, re-roll DT, roll duplicate weapon
// ===================================================================

function OnWaveEnd()
{
	// Reset survive proc gate for next wave
	bDataMissingUsedThisWave = false;
	DataMissingUsesThisWave = 0;

	// Force-end any active glitch (shouldn't normally be active at wave end,
	// but defensive cleanup)
	if (bGlitchActive)
	{
		ClearTimer(NameOf(DeactivateDataMissing));
		bGlitchActive = false;
	}

	// Re-roll the rotating elemental for next wave (Lv 10+)
	if (UpgradeLevel >= 10)
		RollDamageType();

	// Lv 20: roll 10% duplicate
	if (UpgradeLevel >= 20)
	{
		if (FRand() < class'ZTUpgrade_Perk_MissingNO'.default.WaveEndDuplicateChance)
			TryDuplicateWeapon();
	}
}

// ===================================================================
// WEAPON DUPLICATION (Lv 20) - Spawn dropped pickup at player's feet
//
// Approach: Spawn a fresh KFWeapon instance with WMDroppedPickup as its
// drop class, then DropFrom() at player's location. Engine handles the
// pickup actor creation and replication. The Inventory pointer in the
// pickup is the freshly-spawned weapon, so when picked up, the WMDropped-
// Pickup.GiveTo logic creates a proper inventory item via CreateInventory.
//
// Filter: bCanThrow && !bIsBackupWeapon && not a melee weapon. This
// excludes the starter 9mm (bIsBackupWeapon=true on it per WMInventoryManager),
// the perk knife, and welder/syringe (bCanThrow=false on backups).
// ===================================================================

function TryDuplicateWeapon()
{
	local KFPawn_Human Player;
	local KFWeapon KFW, TempWeapon;
	local class<KFWeapon> ChosenClass;
	local array< class<KFWeapon> > Candidates;
	local Vector DropLoc, TossVel;
	local KFPlayerController KFPC;

	Player = KFPawn_Human(Owner);
	if (Player == None || !Player.IsAliveAndWell() || Player.InvManager == None)
		return;

	// Build candidate list: real droppable primary/secondary weapons only
	foreach Player.InvManager.InventoryActors(class'KFWeapon', KFW)
	{
		if (!KFW.bCanThrow)
			continue;
		if (KFW.bIsBackupWeapon)
			continue;
		if (KFWeap_MeleeBase(KFW) != None)
			continue;

		Candidates.AddItem(KFW.Class);
	}

	if (Candidates.Length == 0)
	{
		`log("MissingNO Helper: Duplicate roll succeeded but no candidate weapons");
		return;
	}

	// Pick a random one
	ChosenClass = Candidates[Rand(Candidates.Length)];

	// Spawn a fresh weapon instance owned by the player. The fresh instance
	// has full default ammo via KFWeapon defaults.
	TempWeapon = Player.Spawn(ChosenClass, Player);
	if (TempWeapon == None)
	{
		`log("MissingNO Helper: Failed to spawn weapon instance for" @ ChosenClass);
		return;
	}

	// Use ZR's WMDroppedPickup so the pickup integrates with ZR's pickup
	// rules (sidearm handling, weight checks, etc).
	TempWeapon.DroppedPickupClass = class'ZedternalReborn.WMDroppedPickup';

	// Drop slightly above the player's feet with mild upward velocity so
	// it doesn't fall through the floor.
	DropLoc = Player.Location + Vect(0, 0, 30);
	TossVel = Vect(0, 0, 80);

	TempWeapon.DropFrom(DropLoc, TossVel);

	// Notify
	KFPC = KFPlayerController(Player.Controller);
	if (KFPC != None)
	{
		class'ZTMessageManager'.static.SendCritical(
			KFPC,
			"ITEM DUPLICATED: " $ string(ChosenClass.Name) $ " spawned at your feet"
		);
	}

	PlayMissingNOSound('MissingNO_Duplicate');

	`log("MissingNO Helper: Duplicated" @ ChosenClass @ "for" @ Player.PlayerReplicationInfo.PlayerName);
}

// ===================================================================
// SOUND PLAYBACK
//
// Per SoundImplementationGuide.md: server-side helper looks up the
// registered SoundCue via ZTSoundManager and routes playback through
// ZTPlayerController.ClientPlayBuffSound (a reliable client RPC).
//
// PlaySoundBase from server context will execute silently - the RPC
// route is mandatory.
// ===================================================================

function PlayMissingNOSound(name SoundID)
{
	local ZTPlayerController DKPC;
	local ZTMutator Mutator;
	local SoundCue Sound;
	local KFPawn_Human Player;

	Player = KFPawn_Human(Owner);
	if (Player == None)
		return;

	DKPC = ZTPlayerController(Player.Controller);
	if (DKPC == None)
		return;

	Mutator = class'ZTSoundManager'.static.GetMutator(WorldInfo);
	if (Mutator == None)
	{
		`log("MissingNO Helper: Sound playback failed -" @ SoundID @ "- ZTMutator not found");
		return;
	}

	Sound = class'ZTSoundManager'.static.GetSound(Mutator, SoundID);
	if (Sound == None)
	{
		`log("MissingNO Helper: Sound" @ SoundID @ "not registered in ZTSoundManager");
		return;
	}

	DKPC.ClientPlayBuffSound(Sound);
}

// ===================================================================
// CLEANUP
// ===================================================================

function Cleanup()
{
	ClearTimer(NameOf(DeactivateDataMissing));
	bGlitchActive = false;
}

// ===================================================================
// DEFAULT PROPERTIES
// ===================================================================

defaultproperties
{
	UpgradeLevel=0
	bGlitchActive=false
	bDataMissingUsedThisWave=false
	CurrentDamageTypeIndex=-1

	ROTATING_DT_COUNT=5

	Name="Default__ZTUpgrade_Perk_MissingNO_Helper"
}
