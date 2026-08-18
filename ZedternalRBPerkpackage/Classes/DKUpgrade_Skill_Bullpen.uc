// Bullpen - Fastball synergy: landing kills (Deluxe: any landing) reset the cooldown.
class DKUpgrade_Skill_Bullpen extends DKUpgrade_Skill;

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local DKUpgrade_Perk_Fastball_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'DKUpgrade_Perk_Fastball'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.SetSkillBullpenLevel(upgLevel);
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
		H.SetSkillBullpenLevel(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_Bullpen"

	UpgradeName="Bullpen"
	upgradeDescription(0)="<font color=\"#15d7fa\">Fastball only:</font> if the landing shockwave <font color=\"#ff3399\">kills a zed</font>, your launch cooldown <font color=\"#77d914\">instantly resets</font>."
	upgradeDescription(1)="<font color=\"#15d7fa\">Fastball only:</font> <font color=\"#77d914\">every landing instantly resets</font> your launch cooldown."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Bullpen'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Bullpen_Deluxe'
	Name="Default__DKUpgrade_Skill_Bullpen"
}
