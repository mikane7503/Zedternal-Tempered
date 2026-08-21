// Stack Corruption - MissingNO synergy: flat GLITCH proc chance bonus. Inert without the perk.
class DKUpgrade_Skill_StackCorruption extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> ChanceBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ChanceBonus[0] = 0.05f;
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
		H.SetSkillGlitchBonus(default.ChanceBonus[upgLevel - 1]);
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
		H.SetSkillGlitchBonus(0.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_StackCorruption"

	UpgradeName="Stack Corruption"
	upgradeDescription(0)="<font color=\"#ff00ff\">MissingNO only:</font> GLITCH proc chance <font color=\"#00ff00\">+5%</font>."
	upgradeDescription(1)="<font color=\"#ff00ff\">MissingNO only:</font> GLITCH proc chance <font color=\"#00ff00\">+10%</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_StackCorruption'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_StackCorruption_Deluxe'
	Name="Default__DKUpgrade_Skill_StackCorruption"
}
