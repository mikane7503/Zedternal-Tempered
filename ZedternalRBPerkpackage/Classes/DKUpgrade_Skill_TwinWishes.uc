// Twin Wishes - Wishmaster synergy: grant multiple wishes per trader.
// After the result flash, a fresh offer rolls if the trader is still open.
// Inert without the perk.
class DKUpgrade_Skill_TwinWishes extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<int> WishesPerTrader;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.WishesPerTrader[0] = 2;
		default.WishesPerTrader[1] = 3;
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
		H.SetSkillWishesPerTrader(default.WishesPerTrader[upgLevel - 1]);
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
		H.SetSkillWishesPerTrader(1);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_TwinWishes"

	UpgradeName="Twin Wishes"
	upgradeDescription(0)="<font color=\"#aa5af0\">Wishmaster only:</font> grant <font color=\"#ffc832\">2 wishes</font> per trader time."
	upgradeDescription(1)="<font color=\"#aa5af0\">Wishmaster only:</font> grant <font color=\"#ffc832\">3 wishes</font> per trader time."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_TwinWishes'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_TwinWishes_Deluxe'
	Name="Default__DKUpgrade_Skill_TwinWishes"
}
