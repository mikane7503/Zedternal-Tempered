// Corrupted Save - MissingNO synergy: DATA MISSING procs more often; Deluxe: twice per wave.
// Inert without the perk (and only meaningful at perk level 20).
class DKUpgrade_Skill_CorruptedSave extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> ChanceBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ChanceBonus[0] = 0.10f;
		default.ChanceBonus[1] = 0.10f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_MissingNO_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_MissingNO'.static.GetHelper(OwnerPawn);
	if (H != None)
		H.SetSkillDataMissing(default.ChanceBonus[upgLevel - 1], (upgLevel >= 2) ? 2 : 1);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_MissingNO_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_MissingNO'.static.GetHelper(OwnerPawn);
	if (H != None)
		H.SetSkillDataMissing(0.0f, 1);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_CorruptedSave"

	UpgradeName="Corrupted Save"
	upgradeDescription(0)="<font color=\"#ff00ff\">MissingNO only:</font> <font color=\"#00ff00\">DATA MISSING</font> survival chance <font color=\"#77d914\">+10%</font>."
	upgradeDescription(1)="<font color=\"#ff00ff\">MissingNO only:</font> <font color=\"#00ff00\">DATA MISSING</font> survival chance <font color=\"#77d914\">+10%</font> and can trigger <font color=\"#FFD700\">twice per wave</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CorruptedSave'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CorruptedSave_Deluxe'
	Name="Default__DKUpgrade_Skill_CorruptedSave"
}
