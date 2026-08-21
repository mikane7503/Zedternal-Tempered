// Checksum - universal glitch: a random minibuff each wave, rolled at wave end for
// the next one. Helper stores the roll; conditional hooks read it.
class ZTUpgrade_Skill_Checksum extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> BuffStrength; // damage/speed/reload magnitude per tier
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.BuffStrength[0] = 0.10f;
		default.BuffStrength[1] = 0.20f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ZTUpgrade_Skill_Checksum_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_Checksum_Helper H;

	if (KFPawn_Human(OwnerPawn) == None)
		return None;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_Checksum_Helper', H)
		return H;

	return OwnerPawn.Spawn(class'ZTUpgrade_Skill_Checksum_Helper', OwnerPawn);
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	if (KFPawn_Human(OwnerPawn) != None && OwnerPawn.Role == ROLE_Authority)
		GetHelper(OwnerPawn);
}

static function WaveEnd(int upgLevel, KFPlayerController KFPC)
{
	local ZTUpgrade_Skill_Checksum_Helper H;

	if (KFPC == None || KFPC.Pawn == None)
		return;

	H = GetHelper(KFPC.Pawn);
	if (H != None)
		H.RollBuff();
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Skill_Checksum_Helper H;

	if (DamageInstigator == None || DamageInstigator.Pawn == None)
		return;

	H = GetHelper(DamageInstigator.Pawn);
	if (H != None && H.CurrentBuff == 0)
		InDamage += Round(float(DefaultDamage) * default.BuffStrength[upgLevel - 1]);
}

static simulated function ModifySpeed(out float InSpeed, float DefaultSpeed, int upgLevel, KFPawn OwnerPawn)
{
	local ZTUpgrade_Skill_Checksum_Helper H;

	H = GetHelper(OwnerPawn);
	if (H != None && H.CurrentBuff == 1)
		InSpeed += DefaultSpeed * default.BuffStrength[upgLevel - 1];
}

static simulated function GetReloadRateScale(out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Skill_Checksum_Helper H;

	H = GetHelper(OwnerPawn);
	if (H != None && H.CurrentBuff == 2)
		InReloadRateScale = 1.0f / (1.0f / InReloadRateScale + default.BuffStrength[upgLevel - 1]);
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Skill_Checksum_Helper H;

	if (OwnerPawn == None)
		return;

	H = GetHelper(OwnerPawn);
	if (H != None && H.CurrentBuff == 3)
		InDamage -= Round(float(DefaultDamage) * default.BuffStrength[upgLevel - 1]);
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Skill_Checksum_Helper H;

	if (OwnerPawn == None)
		return;

	foreach OwnerPawn.ChildActors(class'ZTUpgrade_Skill_Checksum_Helper', H)
		H.Destroy();
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_Checksum"

	UpgradeName="Checksum"
	upgradeDescription(0)="Each wave, gain a <font color=\"#00ff00\">random +10% buff</font>: Damage, Speed, Reload or Damage Resistance."
	upgradeDescription(1)="Each wave, gain a <font color=\"#00ff00\">random +20% buff</font>: Damage, Speed, Reload or Damage Resistance."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Checksum'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_Checksum_Deluxe'
	Name="Default__ZTUpgrade_Skill_Checksum"
}
