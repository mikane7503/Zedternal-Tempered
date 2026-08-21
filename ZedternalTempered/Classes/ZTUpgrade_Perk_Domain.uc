// ===================================================================
// ZTUpgrade_Perk_Domain - "Room" perk archetype (Trafalgar-Law-like)
//
// 20-rank perk. Per rank the room grows in RADIUS and DURATION. The active
// kit (cast + 4 wheel actions + collapse burst) lives in
// ZTUpgrade_Perk_Domain_Helper; the SWF wheel + hotkey wiring lives in
// ZTPlayerController / ZTDomainWheelMovie.
//
// Passives below apply only while the room is up and the relevant actor is
// inside it:
//   * Gamma Knife   -> zeds inside take bonus damage   (ModifyDamageGiven)
//   * Domain Guard  -> owner takes reduced damage       (ModifyDamageTaken)
//   * Mes           -> owner lifesteals on hits          (AddVampireHealth)
//   * Scan          -> owner sees zed health             (CanSeeEnemyHealth)
//
// Capstones (PLACEHOLDER stat spikes - confirm desired behavior):
//   * Level 10 -> radius & duration multiplied by the Capstone10 mults.
//   * Level 20 -> action internal cooldown removed, collapse burst doubled.
// ===================================================================
class ZTUpgrade_Perk_Domain extends ZTUpgrade_Perk config(ZedternalUnlimited);

// --- per-rank room scaling ---
var config float RoomRadiusBase;      // UU at rank 0
var config float RoomRadiusPerRank;   // +UU per rank
var config float RoomDurationBase;    // seconds at rank 0
var config float RoomDurationPerRank; // +seconds per rank

// --- flat room params ---
var config float RoomCooldown;
var config float ActionCooldown;     // legacy shared cooldown (unused; kept for config compatibility)
var config float ShiftCooldown;      // per-ability cooldowns
var config float SeverCooldown;
var config float DischargeCooldown;
var config float FreezeCooldown;     // skill-unlocked wheel-ability cooldowns
var config float ShamblesCooldown;
var config float TactCooldown;
var config float InjectionCooldown;
var config float MesCooldown;
var config float TempestCooldown;
var config float ExpandDuration;     // dome grow-out time in seconds
var config float ExpandHoldDuration; // seconds to hold small before growing
var config int   ShockDamage;
var config int   BurstDamage;

// --- skill-unlocked wheel-ability tuning ---
var config float FreezeDuration;     // seconds non-boss zeds stay frozen (Stasis)
var config int   TactDamage;         // slam damage when Tact drops a zed
var config int   InjectionDamage;    // piercing damage per zed hit by Injection Shot
var config float MesDamageBonus;     // extra fraction of owner damage to the Mes target (1.0 = +100%)
var config float MesDuration;        // seconds the Mes mark lasts

// --- Deluxe-tier boosts for the wheel-ability unlock skills ---
var config float FreezeDurationDeluxe;
var config int   TactDamageDeluxe;
var config int   InjectionDamageDeluxe;
var config float MesDamageBonusDeluxe;
var config float MesDurationDeluxe;
var config int   TempestDamageDeluxe; // Deluxe Tempest deals real damage (std = EMP/stun only)

// --- in-room passives ---
var config float OwnerDmgReduction;   // 0..1
var config float ZedDmgBonus;         // fraction of default damage
var config int   MesHeal;             // flat HP per qualifying hit

// --- capstones ---
var config float RadiusCapstone10Mult;
var config float DurationCapstone10Mult;
var config float RadiusCapstone20Mult;  // rank 20 room blowout (covers the map)

var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RoomRadiusBase = 400.0f;
		default.RoomRadiusPerRank = 20.0f;     // rank 20 -> 800 UU (8m)
		default.RoomDurationBase = 8.0f;
		default.RoomDurationPerRank = 0.4f;    // rank 20 -> 16s

		default.RoomCooldown = 45.0f;
		default.ActionCooldown = 3.0f;
		default.ExpandDuration = 2.5f;
		default.ShockDamage = 500;
		default.BurstDamage = 800;

		default.OwnerDmgReduction = 0.35f;
		default.ZedDmgBonus = 0.30f;
		default.MesHeal = 3;

		default.RadiusCapstone10Mult = 1.25f;
		default.DurationCapstone10Mult = 1.25f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 2)
	{
		// Dome now holds small for ExpandHoldDuration, then grows over
		// ExpandDuration. Re-seeds ExpandDuration over any stale early value.
		default.ExpandHoldDuration = 1.0f;
		default.ExpandDuration = 5.0f;

		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 3)
	{
		// Hold the small dome longer before it expands; full expansion unchanged.
		default.ExpandHoldDuration = 3.0f;

		default.MODEVERSION = 3;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 4)
	{
		// Steeper per-rank room growth so ranks 1-19 build into a real arena,
		// then rank 20 blows the room out to cover the whole map.
		//   rank 1  -> 480 UU,  rank 10 -> 1500 UU,  rank 19 -> 2400 UU,
		//   rank 20 -> (400 + 80*20) * 1.25 * 6.0 = 15000 UU.
		default.RoomRadiusPerRank = 80.0f;
		default.RadiusCapstone20Mult = 6.0f;

		default.MODEVERSION = 4;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 5)
	{
		// Per-ability cooldowns. Collapse has none (it ends the room).
		default.ShiftCooldown = 3.0f;
		default.SeverCooldown = 5.0f;
		default.DischargeCooldown = 15.0f;

		default.MODEVERSION = 5;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 6)
	{
		// Six skill-unlocked wheel abilities (Freeze, Shambles, Tact,
		// Injection Shot, Mes, Tempest).
		default.FreezeCooldown = 20.0f;
		default.ShamblesCooldown = 12.0f;
		default.TactCooldown = 12.0f;
		default.InjectionCooldown = 8.0f;
		default.MesCooldown = 25.0f;
		default.TempestCooldown = 18.0f;

		default.FreezeDuration = 5.0f;
		default.TactDamage = 300;
		default.InjectionDamage = 2500;
		default.MesDamageBonus = 1.0f;
		default.MesDuration = 8.0f;

		default.MODEVERSION = 6;
		static.StaticSaveConfig();
	}

	if (default.MODEVERSION < 7)
	{
		// Deluxe-tier boosts for the six wheel-ability unlock skills.
		default.FreezeDurationDeluxe = 8.0f;
		default.TactDamageDeluxe = 700;
		default.InjectionDamageDeluxe = 5000;
		default.MesDamageBonusDeluxe = 2.0f;
		default.MesDurationDeluxe = 12.0f;
		default.TempestDamageDeluxe = 1500;

		default.MODEVERSION = 7;
		static.StaticSaveConfig();
	}
}

// ===================================================================
// HELPER MANAGEMENT (mirrors ZTUpgrade_Perk_JekyllHyde)
// ===================================================================
static function ZTUpgrade_Perk_Domain_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Domain_Helper', H)
			return H;

		H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Domain_Helper', OwnerPawn);
	}

	return H;
}

static simulated function ZTUpgrade_Perk_Domain_Helper FindHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Domain_Helper', H)
			return H;
	}

	return None;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
	{
		H = GetHelper(OwnerPawn);
		if (H != None)
		{
			if (H.DKPC == None)
				H.Initialize(KFPawn_Human(OwnerPawn), ZTPlayerController(OwnerPawn.Controller));
			H.SetPerkLevel(upgLevel);
		}
	}
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Domain_Helper', H)
		{
			H.ForceRevert();
			H.Destroy();
		}
	}
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (KFPC != None && KFPC.Pawn != None)
	{
		H = GetHelper(KFPC.Pawn);
		if (H != None)
		{
			if (H.DKPC == None)
				H.Initialize(KFPawn_Human(KFPC.Pawn), ZTPlayerController(KFPC));
			H.SetPerkLevel(upgLevel);
		}
	}
}

// ===================================================================
// PASSIVES (only while the room is up and the relevant actor is inside)
// ===================================================================
static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None)
		return;

	H = FindHelper(DamageInstigator.Pawn);
	if (H != None)
	{
		if (H.IsActorInRoom(MyKFPM))
			InDamage += Round(float(DefaultDamage) * default.ZedDmgBonus);

		// Mes: the marked target takes extra damage from the Domain owner.
		InDamage = Round(float(InDamage) * H.GetMarkDamageScale(MyKFPM));
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	H = FindHelper(OwnerPawn);
	if (H != None && H.IsOwnerInRoom())
	{
		InDamage = Round(float(InDamage) * (1.0f - default.OwnerDmgReduction));
		if (InDamage < 0)
			InDamage = 0;
	}
}

static function AddVampireHealth(out int InHealth, int DefaultHealth, int upgLevel, KFPlayerController KFPC, class<DamageType> DT)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = FindHelper(KFPC.Pawn);
	if (H != None && H.IsOwnerInRoom())
		InHealth += default.MesHeal;
}

static simulated function bool CanSeeEnemyHealth(int upgLevel, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Domain_Helper H;

	H = FindHelper(OwnerPawn);
	return H != None && H.IsRoomLive();
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hivemind_Rank_0'
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Perk_Domain"
	LocalizeDescriptionLineCount=4

	UpgradeName="Domain"

	upgradeDescription(0)="Press your <font color=\"#15d7fa\">Domain</font> key to deploy a <font color=\"#be4d25\">Room</font> at your feet. Its <font color=\"#77d914\">radius</font> and <font color=\"#77d914\">duration</font> grow with every rank."
	upgradeDescription(1)="While the Room is up: <font color=\"#15d7fa\">hold</font> the key to open the <font color=\"#be4d25\">ability wheel</font>, aim with the mouse, and <font color=\"#15d7fa\">release</font> to cast: <font color=\"#ffaa33\">Shift</font> (teleport), <font color=\"#ffaa33\">Sever</font> (decapitate a non-boss / swap a boss), <font color=\"#ffaa33\">Discharge</font> (AoE), or <font color=\"#ffaa33\">Collapse</font> (end early with a burst)."
	upgradeDescription(2)="Inside your Room you take <font color=\"#77d914\">reduced damage</font>, deal <font color=\"#77d914\">bonus damage</font> to zeds, <font color=\"#ff3399\">lifesteal</font> on hits, and <font color=\"#15d7fa\">see zed health</font>."
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> bigger, longer Room. <font color=\"#8B0000\">LEVEL 20:</font> the Room expands to cover the whole map, with a doubled Collapse burst."

	// Placeholder rank art (reuses Jekyll&Hyde rank icons). Swap for real Domain art.

	Name="Default__ZTUpgrade_Perk_Domain"
}
