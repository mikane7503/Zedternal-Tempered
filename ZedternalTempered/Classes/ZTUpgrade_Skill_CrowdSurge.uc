class ZTUpgrade_Skill_CrowdSurge extends ZTUpgrade_Skill config(ZedternalUnlimited);

// Kills make you faster and sharper
// Melee kills within a window stack movement speed
// At 3+ stacks: see cloaked Stalkers. At 5 stacks: faster weapon switch.

var config array<float> SpeedPerStack;         // +5% / +7% per kill stack
var config array<int> MaxStacks;               // 5 / 5
var config array<int> CloakedThreshold;        // 3 / 2 stacks to see cloaked
var config array<int> SwitchThreshold;         // 5 / 4 stacks for switch speed
var config array<float> SwitchSpeedBonus;      // 0.5 / 0.75 weapon switch bonus
var config array<float> StackDuration;         // 8s / 12s per stack
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.SpeedPerStack[0] = 0.05f;
		default.SpeedPerStack[1] = 0.07f;
		default.MaxStacks[0] = 5;
		default.MaxStacks[1] = 5;
		default.CloakedThreshold[0] = 3;
		default.CloakedThreshold[1] = 2;
		default.SwitchThreshold[0] = 5;
		default.SwitchThreshold[1] = 4;
		default.SwitchSpeedBonus[0] = 0.50f;
		default.SwitchSpeedBonus[1] = 0.75f;
		default.StackDuration[0] = 8.0f;
		default.StackDuration[1] = 12.0f;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.SpeedPerStack.Length = 2;
		default.SpeedPerStack[0] = 0.020000f;
		default.SpeedPerStack[1] = 0.040000f;
		default.MaxStacks.Length = 2;
		default.MaxStacks[0] = 5;
		default.MaxStacks[1] = 5;
		default.CloakedThreshold.Length = 2;
		default.CloakedThreshold[0] = 3;
		default.CloakedThreshold[1] = 2;
		default.SwitchThreshold.Length = 2;
		default.SwitchThreshold[0] = 5;
		default.SwitchThreshold[1] = 4;
		default.SwitchSpeedBonus.Length = 2;
		default.SwitchSpeedBonus[0] = 0.500000f;
		default.SwitchSpeedBonus[1] = 0.750000f;
		default.StackDuration.Length = 2;
		default.StackDuration[0] = 6.000000f;
		default.StackDuration[1] = 9.000000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Skill_CrowdSurge_Helper UPG;

	// Register melee kills
	if (DamageType != None && static.IsMeleeDamageType(DamageType)
		&& MyKFPM != None && MyKFPM.IsAliveAndWell() && (MyKFPM.Health - InDamage) <= 0
		&& DamageInstigator != None && DamageInstigator.Pawn != None)
	{
		UPG = GetHelper(KFPawn(DamageInstigator.Pawn));
		if (UPG != None)
			UPG.AddStack(default.MaxStacks[upgLevel - 1], default.StackDuration[upgLevel - 1]);
	}
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local ZTUpgrade_Skill_CrowdSurge_Helper UPG;

	if (OwnerPawn != None)
	{
		UPG = GetHelperSimulated(OwnerPawn);
		if (UPG != None && UPG.RepStacks > 0)
		{
			InSpeed += DefaultSpeed * default.SpeedPerStack[upgLevel - 1] * float(UPG.RepStacks);
		}
	}
}

static simulated function bool CanSeeCloaked(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Skill_CrowdSurge_Helper UPG;

	if (OwnerPawn != None)
	{
		UPG = GetHelperSimulated(OwnerPawn);
		if (UPG != None && UPG.RepStacks >= default.CloakedThreshold[upgLevel - 1])
			return True;
	}

	return False;
}

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime, float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
	local ZTUpgrade_Skill_CrowdSurge_Helper UPG;

	if (KFW != None && KFW.Instigator != None)
	{
		UPG = GetHelperSimulated(KFPawn(KFW.Instigator));
		if (UPG != None && UPG.RepStacks >= default.SwitchThreshold[upgLevel - 1])
		{
			InSwitchTime = DefaultSwitchTime / (DefaultSwitchTime / InSwitchTime + default.SwitchSpeedBonus[upgLevel - 1]);
		}
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Skill_CrowdSurge_Helper UPG;
	local bool bFound;

	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == Role_Authority)
	{
		bFound = False;
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_CrowdSurge_Helper', UPG)
		{
			bFound = True;
			break;
		}

		if (!bFound)
			OwnerPawn.Spawn(class'ZTUpgrade_Skill_CrowdSurge_Helper', OwnerPawn);
	}
}

static function ZTUpgrade_Skill_CrowdSurge_Helper GetHelper(KFPawn OwnerPawn)
{
	local ZTUpgrade_Skill_CrowdSurge_Helper UPG;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_CrowdSurge_Helper', UPG)
		{
			return UPG;
		}

		if (OwnerPawn.Role == Role_Authority)
			UPG = OwnerPawn.Spawn(class'ZTUpgrade_Skill_CrowdSurge_Helper', OwnerPawn);
	}

	return UPG;
}

static simulated function ZTUpgrade_Skill_CrowdSurge_Helper GetHelperSimulated(KFPawn OwnerPawn)
{
	local ZTUpgrade_Skill_CrowdSurge_Helper UPG;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_CrowdSurge_Helper', UPG)
		{
			return UPG;
		}
	}

	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_CrowdSurge_Helper UPG;

	if (OwnerPawn != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_CrowdSurge_Helper', UPG)
		{
			UPG.Destroy();
		}
	}
}

defaultproperties
{

    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Skill_CrowdSurge]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Skill_CrowdSurge"

	UpgradeName="Crowd Surge"

	UpgradeDescription(0)="<font color=\"#edb82a\">Crowd Surge</font> Melee kills grant speed stacks (max <font color=\"#FFFFFF\">2</font>, <font color=\"#AAAAAA\">6s each</font>). Per stack: <font color=\"#32CD32\">+2% Move Speed</font> At <font color=\"#FFD700\">3+</font> stacks: <font color=\"#87CEEB\">See cloaked enemies</font> At <font color=\"#FFD700\">2</font> stacks: <font color=\"#87CEEB\">Faster weapon switch</font>"
	UpgradeDescription(1)="<font color=\"#edb82a\">Crowd Surge</font> Melee kills grant speed stacks (max <font color=\"#FFFFFF\">5</font>, <font color=\"#AAAAAA\">9s each</font>). Per stack: <font color=\"#32CD32\">+4% Move Speed</font> At <font color=\"#FFD700\">2+</font> stacks: <font color=\"#87CEEB\">See cloaked enemies</font> At <font color=\"#FFD700\">4</font> stacks: <font color=\"#87CEEB\">Faster weapon switch</font>"

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CrowdSurge'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CrowdSurge_Deluxe'

	Name="Default__ZTUpgrade_Skill_CrowdSurge"
}
