// Diablo - Berserker level-20 capstone built around a timed stored-damage pulse.
class ZTUpgrade_Perk_Diablo extends ZTUpgrade_Perk config(ZedternalUnlimited);

var config float HeavyDamagePerLevel;
var config float LargeMeleeDamagePerLevel;
var config float DeathwaveInterval;
var config float DeathwaveRadius;
var config float FearDeathwavePct;
var config float HellDeathwavePct;

var config array<float> ReservoirPct;
var config array<float> RadiusBonus;
var config array<float> CooldownReduction;
var config array<float> MeleeLedgerBonus;
var config array<float> ScorchedWakePct;
var config array<float> EchoPct;
var config array<float> DemonSkinResistance;
var config array<float> BloodTributeHealPct;
var config array<float> HellgateRadiusBonus;
var config array<float> ApocalypsePct;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.HeavyDamagePerLevel = 0.020000f;
		default.LargeMeleeDamagePerLevel = 0.030000f;
		default.DeathwaveInterval = 60.000000f;
		default.DeathwaveRadius = 200.000000f;
		default.FearDeathwavePct = 0.200000f;
		default.HellDeathwavePct = 0.500000f;
		default.ReservoirPct.Length=2; default.ReservoirPct[0] = 0.050000f; default.ReservoirPct[1] = 0.100000f;
		default.RadiusBonus.Length=2; default.RadiusBonus[0] = 50.000000f; default.RadiusBonus[1] = 100.000000f;
		default.CooldownReduction.Length=2; default.CooldownReduction[0] = 10.000000f; default.CooldownReduction[1] = 20.000000f;
		default.MeleeLedgerBonus.Length=2; default.MeleeLedgerBonus[0] = 0.250000f; default.MeleeLedgerBonus[1] = 0.500000f;
		default.ScorchedWakePct.Length=2; default.ScorchedWakePct[0] = 0.050000f; default.ScorchedWakePct[1] = 0.100000f;
		default.EchoPct.Length=2; default.EchoPct[0] = 0.150000f; default.EchoPct[1] = 0.300000f;
		default.DemonSkinResistance.Length=2; default.DemonSkinResistance[0] = 0.100000f; default.DemonSkinResistance[1] = 0.200000f;
		default.BloodTributeHealPct.Length=2; default.BloodTributeHealPct[0] = 0.005000f; default.BloodTributeHealPct[1] = 0.010000f;
		default.HellgateRadiusBonus.Length=2; default.HellgateRadiusBonus[0] = 100.000000f; default.HellgateRadiusBonus[1] = 200.000000f;
		default.ApocalypsePct.Length=2; default.ApocalypsePct[0] = 0.050000f; default.ApocalypsePct[1] = 0.100000f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyHardAttackDamage(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn)
{
	InDamage += Round(float(DefaultDamage) * default.HeavyDamagePerLevel * upgLevel);
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Diablo_Helper H;
	local KFPawn_Human P;

	if (MyKFPM == None || DamageType == class'ZTDT_DiabloDeathwave') return;
	if (MyKFPM.bLargeZed || MyKFPM.IsABoss())
		if (DamageType != None && IsMeleeDamageType(DamageType))
			InDamage += Round(float(DefaultDamage) * default.LargeMeleeDamagePerLevel * upgLevel);
	if (DamageInstigator != None) P = KFPawn_Human(DamageInstigator.Pawn);
	if (P == None && MyKFW != None) P = KFPawn_Human(MyKFW.Instigator);
	H = GetHelper(P);
	if (H != None) H.AccumulateDamage(InDamage, DamageType);
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel,
	KFPawn OwnerPawn, optional class<DamageType> DamageType,
	optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Diablo_Helper H;
	H = GetHelper(OwnerPawn);
	if (H != None && H.HasDemonSkin())
		InDamage = Round(float(InDamage) * (1.0f - H.SkillDemonSkinResistance));
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Diablo_Helper H;
	if (OwnerPawn == None || OwnerPawn.Role != ROLE_Authority) return;
	H = GetHelper(OwnerPawn);
	if (H == None) H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Diablo_Helper', OwnerPawn);
	if (H != None) H.SetPerkLevel(upgLevel);
}

static function ZTUpgrade_Perk_Diablo_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Diablo_Helper H;
	if (OwnerPawn != None) foreach OwnerPawn.ChildActors(class'ZTUpgrade_Perk_Diablo_Helper', H) return H;
	return None;
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Diablo_Helper H;
	H = GetHelper(OwnerPawn);
	if (H != None) H.Destroy();
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Cinder_Rank_0'
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Perk_Diablo"
	LocalizeDescriptionLineCount=3
	UpgradeName="Diablo"
	UpgradeDescription(0)="<font color=\"#FF4500\">Infernal Strength:</font> <font color=\"#FFFFFF\">+2%</font> heavy melee damage and <font color=\"#FFFFFF\">+3%</font> melee damage to large zeds and bosses per level."
	UpgradeDescription(1)="<font color=\"#8B0000\">LEVEL 10 - Dread Deathwave:</font> Every <font color=\"#FFFFFF\">60 seconds</font>, enemies within <font color=\"#FF4500\">2 meters</font> take explosive damage equal to <font color=\"#FFD700\">20%</font> of all damage you dealt during that interval."
	UpgradeDescription(2)="<font color=\"#8B0000\">LEVEL 20 - Hell Deathwave:</font> Dread Deathwave is replaced, not duplicated. It now delivers <font color=\"#FFD700\">50%</font> of stored damage to every enemy in range."
	Name="Default__ZTUpgrade_Perk_Diablo"
}
