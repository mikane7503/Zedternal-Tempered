// Hyde skill - Lingering Beast: after Hyde ends, keep some of its power for a few seconds.
// Opens an "afterglow" window in the helper on revert; hooks read bAfterglowActive
// (these therefore apply in Jekyll form, right after reverting - not gated on bHyde).
class ZTUpgrade_Skill_LingeringBeast extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> Duration;
var config array<float> MeleeFrac;
var config array<float> SpeedFrac;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Duration[0] = 3.0f;   default.Duration[1] = 5.0f;
		default.MeleeFrac[0] = 0.50f; default.MeleeFrac[1] = 0.70f;
		default.SpeedFrac[0] = 0.10f; default.SpeedFrac[1] = 0.15f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (KFPawn_Human(OwnerPawn) == None || OwnerPawn.Role != ROLE_Authority)
		return;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.GetHelper(OwnerPawn);
	if (H == None) return;
	H.bLingering = True;
	H.LingeringDuration = default.Duration[upgLevel - 1];
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H != None) H.ResetLingering();
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;
	if (!IsMeleeDamageType(DamageType))
		return;

	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(DamageInstigator.Pawn);
	if (H == None || !H.bAfterglowActive || H.bShockwaveActive)
		return;

	InDamage += Round(float(DefaultDamage) * default.MeleeFrac[upgLevel - 1]);
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H == None || !H.bAfterglowActive) return;
	InSpeed += DefaultSpeed * default.SpeedFrac[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_LingeringBeast"
	UpgradeName="Lingering Beast"
	upgradeDescription(0)="For <font color=\"#77d914\">3s</font> after reverting, keep <font color=\"#ff3399\">+50%</font> melee damage and <font color=\"#77d914\">+10%</font> speed."
	upgradeDescription(1)="For <font color=\"#77d914\">5s</font> after reverting, keep <font color=\"#ff3399\">+70%</font> melee damage and <font color=\"#77d914\">+15%</font> speed."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_LingeringBeast'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_LingeringBeast_Deluxe'
	Name="Default__ZTUpgrade_Skill_LingeringBeast"
}
