Class DKUpgrade_Perk_TimeTraveler extends DKUpgrade_Perk
	config(ZedternalUnlimited);

var config float Damage;
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
	InDamage -= Round(float(DefaultDamage) * default.Damage * upgLevel);
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
    // --- Localization (auto-generated by mass_localize_dk_upgrades.py) ---
    // Strings live in KFGame/Localization/<lang>/ZedternalRBPerkpackage.<langext>
    // Section: [DKUpgrade_Perk_TimeTraveler]  -- see DKUpgrade_* base class for details.
    bShouldLocalize=True
    LocPackage="ZedternalRBPerkpackage"
    LocSection="DKUpgrade_Perk_TimeTraveler"
    LocalizeDescriptionLineCount=2

    UpgradeName="Time Traveler"
	upgradeDescription(0)="Increase <font color=\"#15d7fa\">all aspects</font> of weapons by <font color=\"#77d914\">%x%%</font>."
	upgradeDescription(1)="Gain <font color=\"#77d914\">+%x seconds</font> of <font color=\"#15d7fa\">ZED Time Duration</font>."
	PerkBonus(0)=(baseValue=0, incValue=1, maxValue=-1)
	PerkBonus(1)=(baseValue=0, incValue=1, maxValue=100)
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_0'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_1'
	UpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_2'
	UpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_3'
	UpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_4'
	UpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
    UpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
    UpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
    UpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
    UpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	UpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	// Legacy (hand-made) artwork icons
	LegacyUpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_0'
	LegacyUpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_1'
	LegacyUpgradeIcon(2)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_2'
	LegacyUpgradeIcon(3)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_3'
	LegacyUpgradeIcon(4)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_4'
	LegacyUpgradeIcon(5)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(6)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(7)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(8)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(9)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(10)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(11)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(12)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(13)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(14)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(15)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(16)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(17)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(18)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(19)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'
	LegacyUpgradeIcon(20)=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_Perk_TimeTraveler_Legacy_Rank_5'

	Name="Default__DKUpgrade_Perk_TimeTraveler"
}