Class ZTUpgrade_Perk_TimeTraveler extends ZTUpgrade_Perk
	config(ZedternalUnlimited);

var config float Damage;
var config float Resistance;
var config float Heal;
var config float KnockdownPower;
var config float MagSize;
var config float MeleeAttackSpeed;
var config float Penetration;
var config float RateOfFire;
var config float Recoil;
var config float ReloadRate;
var config float SpareAmmo;
var config float StumblePower;
var config float StunPower;
var config float Speed;
var config float Spread;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Damage = 0.010000;
		default.Resistance = 0.004000;
		default.Heal = 0.010000;
		default.KnockdownPower = 0.010000;
		default.MagSize = 0.010000;
		default.MeleeAttackSpeed = 0.010000;
		default.Penetration = 0.010000;
		default.RateOfFire = 0.010000;
		default.Recoil = 0.010000;
		default.ReloadRate = 0.010000;
		default.SpareAmmo = 0.010000;
		default.StumblePower = 0.010000;
		default.StunPower = 0.010000;
		default.Speed = 0.010000;
		default.Spread = 0.010000;

		// BEGIN TEMPERED INI DEFAULTS (generated; do not edit by hand)
		default.Damage = 0.010000f;
		default.Resistance = 0.004000f;
		default.Heal = 0.010000f;
		default.KnockdownPower = 0.010000f;
		default.MagSize = 0.010000f;
		default.MeleeAttackSpeed = 0.010000f;
		default.Penetration = 0.010000f;
		default.RateOfFire = 0.010000f;
		default.Recoil = 0.010000f;
		default.ReloadRate = 0.010000f;
		default.SpareAmmo = 0.010000f;
		default.StumblePower = 0.010000f;
		default.StunPower = 0.010000f;
		default.Speed = 0.010000f;
		default.Spread = 0.010000f;
		// END TEMPERED INI DEFAULTS
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}


static function ModifyDamageGiven( out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	InDamage += Round(float(DefaultDamage) * default.Damage * upgLevel);
}

static function ModifyDamageTaken( out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	InDamage -= Round(float(DefaultDamage) * default.Resistance * upgLevel);
}


static function ModifyHardAttackDamage( out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn)
{
	InDamage += Round(float(DefaultDamage) * default.Damage * upgLevel);
}

static function ModifyHealAmount( out float InHealAmount, float DefaultHealAmount, int upgLevel)
{
	InHealAmount += DefaultHealAmount * default.Heal * upgLevel;
}

static function ModifyKnockdownPower( out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=false)
{
	InKnockdownPower += DefaultKnockdownPower * default.KnockdownPower * upgLevel;
}

static simulated function ModifyMagSizeAndNumber( out int InMagazineCapacity, int DefaultMagazineCapacity, int upgLevel, KFWeapon KFW, optional array< Class<KFPerk> > WeaponPerkClass, optional bool bSecondary=false, optional name WeaponClassname )
{
	InMagazineCapacity += Round(float(DefaultMagazineCapacity) * default.MagSize * upgLevel);
}

static simulated function ModifyMeleeAttackSpeed( out float InDuration, float DefaultDuration, int upgLevel, KFWeapon KFW)
{
	InDuration = DefaultDuration / (DefaultDuration/InDuration + default.MeleeAttackSpeed * upgLevel);
}


static simulated function ModifyPenetration( out float InPenetration, float DefaultPenetration, int upgLevel, class<KFDamageType> DamageType, KFPawn OwnerPawn, optional bool bForce)
{
	InPenetration += DefaultPenetration * default.Penetration * upgLevel;
}

static simulated function ModifyRateOfFire( out float InRate, float DefaultRate, int upgLevel, KFWeapon KFW )
{
	InRate = DefaultRate / (DefaultRate/InRate + default.RateOfFire * upgLevel);
}

static simulated function ModifyRecoil( out float InRecoilModifier, float DefaultRecoilModifier, int upgLevel, KFWeapon KFW)
{
	InRecoilModifier -= DefaultRecoilModifier * default.Recoil * upgLevel;
}

static simulated function GetReloadRateScale( out float InReloadRateScale, int upgLevel, KFWeapon KFW, KFPawn OwnerPawn)
{
	InReloadRateScale = 1.f / (1.f/InReloadRateScale + default.ReloadRate * upgLevel);
}


static simulated function ModifySpareAmmoAmount( out int InSpareAmmo, int DefaultSpareAmmo, int upgLevel, KFWeapon KFW, optional const out STraderItem TraderItem, optional bool bSecondary=false )
{
	if (!bSecondary)
		InSpareAmmo += Round(float(DefaultSpareAmmo) * default.SpareAmmo * upgLevel);
}

static function ModifyStumblePower( out float InStumblePower, float DefaultStumblePower, int upgLevel, optional KFPawn KFP, optional class<KFDamageType> DamageType, optional out float CooldownModifier, optional byte BodyPart, optional KFPawn OwnerPawn)
{
	InStumblePower += DefaultStumblePower * default.StumblePower * upgLevel;
}

static function ModifyStunPower( out float InStunPower, float DefaultStunPower, int upgLevel, optional class<DamageType> DamageType, optional byte HitZoneIdx)
{
	InStunPower += DefaultStunPower * default.StunPower * upgLevel;
}

static simulated function ModifyWeaponSwitchTime(out float InSwitchTime, float DefaultSwitchTime, int upgLevel, KFWeapon KFW)
{
	InSwitchTime = DefaultSwitchTime / (DefaultSwitchTime/InSwitchTime + default.Speed * upgLevel);
}

static simulated function ModifyTightChokePassive( out float tightChokeFactor, int upgLevel)
{
	tightChokeFactor -= default.Spread * upgLevel;
}

static simulated function GetZedTimeExtension(out float InExtension, float DefaultExtension, int upgLevel)
{
	InExtension += float(Min(upgLevel, 100));
}

defaultproperties
{
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Rank_0'
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalTempered.<langext>
    // Section: [ZTUpgrade_Perk_TimeTraveler]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalTempered"
    LocSection="ZTUpgrade_Perk_TimeTraveler"
    LocalizeDescriptionLineCount=2

    UpgradeName="Time Traveler"
	upgradeDescription(0)="Increase <font color=\"#15d7fa\">weapon stats</font> by <font color=\"#77d914\">1% per rank</font> and gain <font color=\"#77d914\">0.4% damage resistance per rank</font>."
	upgradeDescription(1)="Gain <font color=\"#77d914\">+%x seconds</font> of <font color=\"#15d7fa\">ZED Time Duration</font>."
	PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)
	PerkBonus(1)=(baseValue=0, incValue=1, maxValue=100)
	// Legacy (hand-made) artwork icons

	Name="Default__ZTUpgrade_Perk_TimeTraveler"
}
