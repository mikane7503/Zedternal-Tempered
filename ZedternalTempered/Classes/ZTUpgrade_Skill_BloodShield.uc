// ===================================================================
// ZTUpgrade_Skill_BloodShield - Emergency Siphon Barrier
// When you drop below 30% HP, all active siphon connections are
// consumed to grant temporary damage resistance. More siphons
// consumed = bigger shield. Once-per-wave cooldown.
//
// Standard: 6% DR per consumed siphon, 6 second duration
// Deluxe:   10% DR per consumed siphon, 10 second duration
//
// REQUIRES: ZTUpgrade_Perk_Parasite_Helper must expose:
//   - GetSiphonedEnemyCount() : int
//   - ConsumeAllSiphons() : int  (clears all siphons, returns count)
// ===================================================================
class ZTUpgrade_Skill_BloodShield extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> DRPerSiphon;
var config array<float> ShieldDuration;
var config float HealthThreshold;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DRPerSiphon[0] = 0.06f;
		default.DRPerSiphon[1] = 0.10f;
		default.ShieldDuration[0] = 6.0f;
		default.ShieldDuration[1] = 10.0f;
		default.HealthThreshold = 0.30f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.DRPerSiphon.Length = 2;
		default.DRPerSiphon[0] = 0.015000f;
		default.DRPerSiphon[1] = 0.025000f;
		default.ShieldDuration.Length = 2;
		default.ShieldDuration[0] = 6.000000f;
		default.ShieldDuration[1] = 10.000000f;
		default.HealthThreshold = 0.300000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


// ===================================================================
// On Damage Taken: Check for shield trigger + apply DR
// ===================================================================
static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel,
	KFPawn OwnerPawn, optional class<DamageType> DamageType,
	optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Skill_BloodShield_Helper Helper;
	local ZTUpgrade_Perk_Parasite_Helper ParasiteHelper;
	local int SiphonCount;

	if (OwnerPawn == None || InDamage <= 0)
		return;

	Helper = GetHelper(OwnerPawn);
	if (Helper == None)
		return;

	// If shield is active, apply DR
	if (Helper.bShieldActive)
	{
		InDamage -= Round(float(DefaultDamage) * Helper.CurrentDR);
		if (InDamage < 1)
			InDamage = 1;
		return;
	}

	// Check if this hit would bring us below threshold
	if (!Helper.bOnCooldown && (OwnerPawn.Health - InDamage) < int(float(OwnerPawn.HealthMax) * default.HealthThreshold))
	{
		// Find Parasite helper and consume siphons
		ParasiteHelper = GetParasiteHelper(OwnerPawn);
		if (ParasiteHelper != None)
		{
			SiphonCount = ParasiteHelper.ConsumeAllSiphons();
			if (SiphonCount > 0)
			{
				Helper.ActivateShield(
					FMin(default.DRPerSiphon[upgLevel - 1] * float(SiphonCount), 0.30f),
					default.ShieldDuration[upgLevel - 1]
				);

				// Apply DR to this hit too
				InDamage -= Round(float(DefaultDamage) * Helper.CurrentDR);
				if (InDamage < 1)
					InDamage = 1;
			}
		}
	}
}

// ===================================================================
// Find Parasite Perk Helper
// ===================================================================
static function ZTUpgrade_Perk_Parasite_Helper GetParasiteHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Parasite_Helper PHelper;

	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Parasite_Helper', PHelper)
			return PHelper;
	}

	return None;
}

// ===================================================================
// Helper Management
// ===================================================================
static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Skill_BloodShield_Helper UPG;
	local bool bFound;

	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
	{
		bFound = False;
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_BloodShield_Helper', UPG)
		{
			bFound = True;
			break;
		}

		if (!bFound)
			OwnerPawn.Spawn(class'ZTUpgrade_Skill_BloodShield_Helper', OwnerPawn);
	}
}

static function ZTUpgrade_Skill_BloodShield_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_BloodShield_Helper UPG;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_BloodShield_Helper', UPG)
			return UPG;

		if (OwnerPawn.Role == Role_Authority)
			UPG = OwnerPawn.Spawn(class'ZTUpgrade_Skill_BloodShield_Helper', OwnerPawn);
	}

	return UPG;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_BloodShield_Helper UPG;

	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_BloodShield_Helper', UPG)
			UPG.Destroy();
	}
}

// Reset cooldown at wave end
static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Skill_BloodShield_Helper Helper;

	if (KFPC.Pawn != None)
	{
		Helper = GetHelper(KFPC.Pawn);
		if (Helper != None)
			Helper.ResetCooldown();
	}
}

defaultproperties
{

    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Skill_BloodShield]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Skill_BloodShield"

	UpgradeName="Blood Shield"
	UpgradeDescription(0)="<font color=\"#B40028\">Blood Shield:</font> Below <font color=\"#FFFFFF\">30%</font> HP, consume all siphons for <font color=\"#FFFFFF\">1.5%</font> damage resistance per siphon (<font color=\"#FFFFFF\">6s</font>). Once per wave"
	UpgradeDescription(1)="<font color=\"#FFD700\">[DELUXE]</font> <font color=\"#B40028\">Blood Shield:</font> Below <font color=\"#FFFFFF\">30%</font> HP, consume all siphons for <font color=\"#FFFFFF\">2.5%</font> damage resistance per siphon (<font color=\"#FFFFFF\">10s</font>). Once per wave"

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_BloodShield'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_BloodShield_Deluxe'

	Name="Default__ZTUpgrade_Skill_BloodShield"
}
