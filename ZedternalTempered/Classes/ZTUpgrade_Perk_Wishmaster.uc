// ===================================================================
// ZTUpgrade_Perk_Wishmaster - "Careful what you wish for"
//
// Every trader time you are offered 3 wishes (4 at Level 20) from a
// pool of 10. Pick a wish (Cycle/Confirm keys, default Comma/Period),
// then pick a target from up to 3 randomly drawn players (can include
// yourself; solo = only yourself). 25% of wishes CORRUPT and apply
// their exact opposite (15% at Level 10).
//
// All selection/apply machinery lives in the helper. Guardian Angel /
// corrupted first-hit interception lives in ZTGameInfo ReduceDamage
// (MIRRORED in both GameInfos), reading ZTWish_Buff on the victim.
// ===================================================================
class ZTUpgrade_Perk_Wishmaster extends ZTUpgrade_Perk
	config(ZedternalUnlimited);

var config float CorruptionChance;      // base corruption roll
var config float CorruptionChanceL10;   // corruption roll from level 10
var config int WishOffersBase;          // wishes offered per trader
var config int WishOffersL20;           // wishes offered from level 20
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.CorruptionChance = 0.25f;
		default.CorruptionChanceL10 = 0.15f;
		default.WishOffersBase = 3;
		default.WishOffersL20 = 4;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ZTUpgrade_Perk_Wishmaster_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Wishmaster_Helper H;

	if (KFPawn_Human(OwnerPawn) == None)
		return None;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Wishmaster_Helper', H)
		return H;

	H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Wishmaster_Helper', OwnerPawn);
	return H;
}

// Never spawns - safe for client-side simulated hooks.
static simulated function ZTUpgrade_Perk_Wishmaster_Helper FindHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Wishmaster_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Wishmaster_Helper', H)
			return H;
	}

	return None;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Wishmaster_Helper H;

	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
	{
		H = GetHelper(OwnerPawn);
		if (H != None)
			H.SetPerkLevel(upgLevel);
	}
}

// Wave end = trader opens: roll this trader's wish offer.
static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Perk_Wishmaster_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = GetHelper(KFPC.Pawn);
	if (H != None)
	{
		H.SetPerkLevel(upgLevel);
		H.StartWishOffer();
	}
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Wishmaster_Helper H;

	if (KFPawn_Human(OwnerPawn) != None)
	{
		foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Wishmaster_Helper', H)
			H.Destroy();
	}
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Perk_Wishmaster"
	LocalizeDescriptionLineCount=5

	UpgradeName="Wishmaster"
	upgradeDescription(0)="Every trader time you are offered <font color=\"#ffc832\">3 wishes</font> - dosh, health, armor, ammo, blessings and more."
	upgradeDescription(1)="Press <font color=\"#ffc832\">Comma</font> to cycle and <font color=\"#ffc832\">Period</font> to confirm: first the wish, then which player receives it (drawn at random - it can be you)."
	upgradeDescription(2)="But beware: <font color=\"#be4d25\">25%</font> of wishes <font color=\"#8B0000\">CORRUPT</font> and apply their exact <font color=\"#8B0000\">opposite</font>."
	upgradeDescription(3)="<font color=\"#8B0000\">LEVEL 10:</font> Corruption chance drops to <font color=\"#77d914\">15%</font>."
	upgradeDescription(4)="<font color=\"#8B0000\">LEVEL 20:</font> You are offered <font color=\"#FFD700\">4 wishes</font> to choose from."

	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'
	$10'

	Name="Default__ZTUpgrade_Perk_Wishmaster"
}
