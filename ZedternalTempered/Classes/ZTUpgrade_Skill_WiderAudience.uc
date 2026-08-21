// Wider Audience - Wishmaster synergy: more candidate players per wish.
// Inert without the perk (and only matters in fuller lobbies).
class ZTUpgrade_Skill_WiderAudience extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<int> CandidateCount;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.CandidateCount[0] = 4;
		default.CandidateCount[1] = 6;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Wishmaster_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_Wishmaster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillCandidateCount(default.CandidateCount[upgLevel - 1]);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Wishmaster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Wishmaster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillCandidateCount(3);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_WiderAudience"

	UpgradeName="Wider Audience"
	upgradeDescription(0)="<font color=\"#aa5af0\">Wishmaster only:</font> wishes offer up to <font color=\"#ffc832\">4 candidate players</font> to choose from."
	upgradeDescription(1)="<font color=\"#aa5af0\">Wishmaster only:</font> wishes offer up to <font color=\"#ffc832\">6 candidate players</font> to choose from."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_WiderAudience'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_WiderAudience_Deluxe'
	Name="Default__ZTUpgrade_Skill_WiderAudience"
}
