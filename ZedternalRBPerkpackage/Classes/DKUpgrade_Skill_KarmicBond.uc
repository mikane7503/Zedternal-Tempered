// Karmic Bond - Wishmaster synergy: wishing on a teammate echoes a scaled copy
// of the outcome onto you - blessings AND corruptions. Inert without the perk.
class DKUpgrade_Skill_KarmicBond extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> KarmicScale;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.KarmicScale[0] = 0.50f;
		default.KarmicScale[1] = 1.00f;
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
		H.SetSkillKarmicScale(default.KarmicScale[upgLevel - 1]);
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
		H.SetSkillKarmicScale(0.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_KarmicBond"

	UpgradeName="Karmic Bond"
	upgradeDescription(0)="<font color=\"#aa5af0\">Wishmaster only:</font> wishes granted to teammates echo onto you at <font color=\"#77d914\">half strength</font> - even <font color=\"#be4d25\">corrupted ones</font>."
	upgradeDescription(1)="<font color=\"#aa5af0\">Wishmaster only:</font> wishes granted to teammates echo onto you at <font color=\"#77d914\">FULL strength</font> - even <font color=\"#be4d25\">corrupted ones</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_KarmicBond'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_KarmicBond_Deluxe'
	Name="Default__DKUpgrade_Skill_KarmicBond"
}
