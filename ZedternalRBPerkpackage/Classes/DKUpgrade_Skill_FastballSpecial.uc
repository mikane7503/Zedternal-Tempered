// Fastball Special - Fastball synergy: your payload lands with double heal + bonus armor.
class DKUpgrade_Skill_FastballSpecial extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Fastball_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillPayloadCareLevel(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Fastball_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillPayloadCareLevel(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_FastballSpecial"

	UpgradeName="Fastball Special"
	upgradeDescription(0)="<font color=\"#15d7fa\">Fastball only:</font> your payload's landing heal is <font color=\"#77d914\">doubled</font> and they gain <font color=\"#77d914\">+15 Armor</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Fastball only:</font> your payload's landing heal is <font color=\"#77d914\">doubled</font> and they gain <font color=\"#77d914\">+30 Armor</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FastballSpecial'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FastballSpecial_Deluxe'
	Name="Default__DKUpgrade_Skill_FastballSpecial"
}
