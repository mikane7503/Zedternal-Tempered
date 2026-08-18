// Silver Tongue - Wishmaster synergy: safer wishes. Inert without the perk.
class DKUpgrade_Skill_SilverTongue extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> CorruptionReduction;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.CorruptionReduction[0] = 0.05f;
		default.CorruptionReduction[1] = 0.10f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Wishmaster_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Wishmaster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillCorruptionDelta(-default.CorruptionReduction[upgLevel - 1]);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Wishmaster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Wishmaster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillCorruptionDelta(0.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_SilverTongue"

	UpgradeName="Silver Tongue"
	upgradeDescription(0)="<font color=\"#aa5af0\">Wishmaster only:</font> wish corruption chance <font color=\"#77d914\">-5%</font>."
	upgradeDescription(1)="<font color=\"#aa5af0\">Wishmaster only:</font> wish corruption chance <font color=\"#77d914\">-10%</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SilverTongue'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_SilverTongue_Deluxe'
	Name="Default__DKUpgrade_Skill_SilverTongue"
}
