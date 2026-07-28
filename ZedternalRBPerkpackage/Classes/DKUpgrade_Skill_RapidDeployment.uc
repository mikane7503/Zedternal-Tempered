// ===================================================================
// DKUpgrade_Skill_RapidDeployment - passive Domain skill.
//
// Shaves the Room recharge AND every wheel-ability cooldown (Standard
// -20%, Deluxe -35%). Pushes its owned level into the Domain helper,
// which applies the reduction live in GetEffectiveRoomCooldown() and
// GetActionCooldown(). Does nothing without the Domain perk.
// ===================================================================
class DKUpgrade_Skill_RapidDeployment extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> CooldownReduction;    // [standard, deluxe] fraction
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.CooldownReduction[0] = 0.20f;
		default.CooldownReduction[1] = 0.35f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyRapidDeployment(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyRapidDeployment(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyRapidDeployment(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_RapidDeployment"

	UpgradeName="Rapid Deployment"
	upgradeDescription(0)="<font color=\"#ffaa33\">20% shorter</font> Room recharge and ability cooldowns."
	upgradeDescription(1)="<font color=\"#ffaa33\">35% shorter</font> Room recharge and ability cooldowns."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_RapidDeployment'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_RapidDeployment_Deluxe'

	Name="Default__DKUpgrade_Skill_RapidDeployment"
}
