class ZTUpgrade_Perk_Hollow extends ZTUpgrade_Perk config(ZedternalUnlimited);

// Hollow is the Demolitionist rank-15 branch.  It no longer clones every
// weapon in the game; all ordinary bonuses operate on Demolitionist weapons
// and damage types, while only the compact mastery whitelist has a reward gun.
var config float ExplosiveDamagePerLevel;
var config float ExplosiveStumblePerLevel;
var config float CompressionDamage;
var config float BossCompressionScale;
var config int MasteryKillsRequired;
var config int MaxVoidCharges;
var config float DamagePerVoidCharge;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 2)
	{
		default.ExplosiveDamagePerLevel = 0.015f;
		default.ExplosiveStumblePerLevel = 0.020f;
		default.CompressionDamage = 0.150f;
		default.BossCompressionScale = 0.5f;
		default.MasteryKillsRequired = 1000;
		default.MaxVoidCharges = 10;
		default.DamagePerVoidCharge = 0.05f;
		default.MODEVERSION = 2;
		static.StaticSaveConfig();
	}
}

static function bool IsDemolitionDamage(optional KFWeapon KFW, optional class<KFDamageType> DamageType)
{
	return (KFW != None && IsWeaponOnSpecificPerk(KFW, class'KFGame.KFPerk_Demolitionist'))
		|| (DamageType != None && IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Demolitionist'));
}

static function bool IsHollowWeapon(KFWeapon KFW)
{
	return KFW != None && InStr(Caps(string(KFW.Class.Name)), "_HOLLOW") >= 0;
}

static function string NormalizeWeaponName(string RawName)
{
	local int P;
	RawName = Repl(RawName, "ZTWeap_", "", false);
	RawName = Repl(RawName, "KFWeap_", "", false);
	P = InStr(Caps(RawName), "_HOLLOW");
	if (P >= 0)
		RawName = Left(RawName, P);
	return RawName;
}

static function bool IsMeleeWeapon(KFWeapon KFW)
{
	return KFW != None && IsWeaponOnSpecificPerk(KFW, class'KFGame.KFPerk_Berserker');
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel,
	optional Actor DamageCauser, optional KFPawn_Monster MyKFPM,
	optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType,
	optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local ZTUpgrade_Perk_Hollow_Helper H;
	local float Bonus;

	if (!IsDemolitionDamage(MyKFW, DamageType))
		return;

	Bonus = default.ExplosiveDamagePerLevel * upgLevel;
	if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank1Level)
	{
		if (MyKFPM != None && MyKFPM.Class.static.IsABoss())
			Bonus += default.CompressionDamage * default.BossCompressionScale;
		else
			Bonus += default.CompressionDamage;
	}

	// Mastery reward weapons receive exactly +100% base damage.
	if (IsHollowWeapon(MyKFW))
		Bonus += 1.0f;

	if (DamageInstigator != None && DamageInstigator.Pawn != None)
	{
		H = GetHelper(DamageInstigator.Pawn);
		if (H != None)
		{
			H.PerkLevel = upgLevel;
			if (upgLevel >= class'ZTConfig_Capstone'.default.Capstone_Rank2Level
				&& MyKFPM != None && (MyKFPM.bLargeZed || MyKFPM.Class.static.IsABoss()))
				Bonus += H.ConsumeVoidChargeBonus();

			if (MyKFPM != None && InDamage + Round(float(DefaultDamage) * Bonus) >= MyKFPM.Health)
				H.RegisterDemolitionKill(MyKFW);
		}
	}

	InDamage += Round(float(DefaultDamage) * Bonus);
}

static function ModifyStumblePower(out float InStumblePower, float DefaultStumblePower,
	int upgLevel, optional KFPawn KFP, optional class<KFDamageType> DamageType,
	optional out float CooldownModifier, optional byte BodyPart, optional KFPawn OwnerPawn)
{
	if (DamageType != None && IsDamageTypeOnSpecificPerk(DamageType, class'KFGame.KFPerk_Demolitionist'))
		InStumblePower += DefaultStumblePower * default.ExplosiveStumblePerLevel * upgLevel;
}

static simulated function ModifyRecoil(out float InRecoilModifier,
	float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
	if (IsHollowWeapon(KFW))
		InRecoilModifier = FMin(InRecoilModifier, DefaultRecoilModifier * 0.10f);
}

static simulated function ModifySpread(out float InSpreadModifier,
	float DefaultSpreadModifier, int upgLevel, KFWeapon KFW)
{
	if (IsHollowWeapon(KFW))
		InSpreadModifier = FMin(InSpreadModifier, DefaultSpreadModifier * 0.10f);
}

static function ZTUpgrade_Perk_Hollow_Helper GetHelper(Pawn OwnerPawn)
{
	local ZTUpgrade_Perk_Hollow_Helper H;
	if (OwnerPawn == None) return None;
	foreach OwnerPawn.WorldInfo.DynamicActors(class'ZTUpgrade_Perk_Hollow_Helper', H)
	{
		if (H.PlayerPC == OwnerPawn.Controller || H.Owner == OwnerPawn.Controller)
		{
			H.Initialize(KFPawn_Human(OwnerPawn));
			return H;
		}
	}
	if (OwnerPawn.Role == ROLE_Authority)
	{
		H = OwnerPawn.Spawn(class'ZTUpgrade_Perk_Hollow_Helper', OwnerPawn.Controller);
		if (H != None) H.Initialize(KFPawn_Human(OwnerPawn));
	}
	return H;
}

static simulated function InitiateWeapon(int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_Hollow_Helper H;
	if (OwnerPawn != None && OwnerPawn.Role == ROLE_Authority)
	{
		H = GetHelper(OwnerPawn);
		if (H != None) H.PerkLevel = upgLevel;
	}
}

static simulated function DeleteHelperClass(Pawn OwnerPawn)
{
	// Mastery is match-persistent and belongs to the controller, not a pawn.
	// Keep the helper across death/respawn; it is destroyed with the controller.
}

defaultproperties
{
	ExplosiveDamagePerLevel=0.015
	ExplosiveStumblePerLevel=0.020
	CompressionDamage=0.150
	BossCompressionScale=0.500
	MasteryKillsRequired=1000
	MaxVoidCharges=10
	DamagePerVoidCharge=0.050
	MODEVERSION=2

	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Perk_Hollow"
	LocalizeDescriptionLineCount=4
	UpgradeName="Hollow"
	UpgradeDescription(0)="Per level: Demolitionist explosive damage +1.5% and stumble power +2%."
	UpgradeDescription(1)="Rank 10 - Void Compression: Demolitionist explosions deal 15% additional damage (7.5% to bosses)."
	UpgradeDescription(2)="Rank 20 - Event Horizon: explosive kills charge the void. The next hit on a large zed or boss consumes up to 10 charges for +5% damage each."
	UpgradeDescription(3)="Mastery: earn 1,000 kills with an individual Demolitionist weapon to unlock its free Hollow version: +100% damage, -90% recoil and spread."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_Hollow_Rank_0'
	Name="Default__ZTUpgrade_Perk_Hollow"
}
