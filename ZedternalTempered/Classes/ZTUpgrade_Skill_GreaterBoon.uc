// Greater Boon - Wishmaster synergy: numeric wish amounts scaled up.
// Corrupted losses scale too - greed cuts both ways. Inert without the perk.
class ZTUpgrade_Skill_GreaterBoon extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> PotencyMult;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.PotencyMult[0] = 1.50f;
		default.PotencyMult[1] = 2.00f;
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
		H.SetSkillPotencyMult(default.PotencyMult[upgLevel - 1]);
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
		H.SetSkillPotencyMult(1.0f);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_GreaterBoon"

	UpgradeName="Greater Boon"
	upgradeDescription(0)="<font color=\"#aa5af0\">Wishmaster only:</font> wish amounts are <font color=\"#77d914\">50% larger</font> - including <font color=\"#be4d25\">corrupted losses</font>."
	upgradeDescription(1)="<font color=\"#aa5af0\">Wishmaster only:</font> wish amounts are <font color=\"#77d914\">DOUBLED</font> - including <font color=\"#be4d25\">corrupted losses</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GreaterBoon'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GreaterBoon_Deluxe'
	Name="Default__ZTUpgrade_Skill_GreaterBoon"
}
