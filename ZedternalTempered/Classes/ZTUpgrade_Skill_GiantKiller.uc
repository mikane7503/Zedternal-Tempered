// ===================================================================
// ZTUpgrade_Skill_GiantKiller - Speedfreak Blink Strike skill.
//
// Multiplies the reduced "giant/boss chunk" of each Blink Strike
// (Standard +50%, Deluxe +100% of that chunk). Pushes its owned level
// into the Speedster helper, which scales the large-zed multiplier in
// StrikeTarget(). Does nothing without the Speedfreak perk.
// ===================================================================
class ZTUpgrade_Skill_GiantKiller extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> ChunkBonus;    // [standard, deluxe] fraction added to the large-zed multiplier
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.ChunkBonus[0] = 0.50f;
		default.ChunkBonus[1] = 1.00f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyGiantKiller(upgLevel);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(KFPC.Pawn);
	if (H != None)
		H.ApplyGiantKiller(upgLevel);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Speedster_Helper H;

	if (OwnerPawn == None)
		return;

	H = class'ZTUpgrade_Perk_Speedster'.static.FindHelper(OwnerPawn);
	if (H != None)
		H.ApplyGiantKiller(0);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_GiantKiller"

	UpgradeName="Giant-Killer"
	upgradeDescription(0)="<font color=\"#be4d25\">Blink Strike</font> hits giants and bosses <font color=\"#77d914\">50% harder</font>."
	upgradeDescription(1)="<font color=\"#be4d25\">Blink Strike</font> hits giants and bosses <font color=\"#77d914\">twice as hard</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GiantKiller'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GiantKiller_Deluxe'

	Name="Default__ZTUpgrade_Skill_GiantKiller"
}
