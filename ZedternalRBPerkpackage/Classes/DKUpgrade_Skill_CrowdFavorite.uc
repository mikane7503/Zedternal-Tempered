// Crowd Favorite - Goalkeeper synergy: catches patch up nearby allies. Inert without the perk.
class DKUpgrade_Skill_CrowdFavorite extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Goalkeeper_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Goalkeeper'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillCrowdLevel(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	if (KFPC != None && KFPC.Pawn != None)
		InitiateWeapon(upgLevel, None, KFPawn(KFPC.Pawn));
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local DKUpgrade_Perk_Goalkeeper_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'DKUpgrade_Perk_Goalkeeper'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillCrowdLevel(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_CrowdFavorite"

	UpgradeName="Crowd Favorite"
	upgradeDescription(0)="<font color=\"#15d7fa\">Goalkeeper only:</font> every catch heals nearby teammates for <font color=\"#77d914\">5 HP</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Goalkeeper only:</font> every catch heals nearby teammates for <font color=\"#77d914\">10 HP</font> and grants them <font color=\"#77d914\">10 Armor</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CrowdFavorite'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_CrowdFavorite_Deluxe'
	Name="Default__DKUpgrade_Skill_CrowdFavorite"
}
