// Hyde skill - Concussive Roar: Hyde melee hits knock down and stumble with brutal force.
class ZTUpgrade_Skill_ConcussiveRoar extends ZTUpgrade_Skill config(ZedternalUnlimited);

var config array<float> Knockdown;
var config array<float> Stumble;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.Knockdown[0] = 0.5f;  default.Knockdown[1] = 1.0f;
		default.Stumble[0] = 0.5f;    default.Stumble[1] = 1.0f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyKnockdownPower(out float InKnockdownPower, float DefaultKnockdownPower, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional byte BodyPart, optional bool bIsSprinting=False)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H == None || !H.bHyde) return;
	InKnockdownPower += DefaultKnockdownPower * default.Knockdown[upgLevel - 1];
}

static function ModifyStumblePower(out float InStumblePower, float DefaultStumblePower, int upgLevel, optional KFPawn KFP, optional class<KFDamageType> DamageType, optional out float CooldownModifier, optional byte BodyPart, optional KFPawn OwnerPawn)
{
	local ZTUpgrade_Perk_JekyllHyde_Helper H;
	if (OwnerPawn == None) return;   // OwnerPawn is the trailing optional; gate only when present
	H = class'ZTUpgrade_Perk_JekyllHyde'.static.FindHelper(OwnerPawn);
	if (H == None || !H.bHyde) return;
	InStumblePower += DefaultStumblePower * default.Stumble[upgLevel - 1];
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_ConcussiveRoar"
	UpgradeName="Concussive Roar"
	upgradeDescription(0)="As <font color=\"#be4d25\">Mr. Hyde</font>, melee hits gain <font color=\"#77d914\">+50%</font> knockdown and stumble power."
	upgradeDescription(1)="As <font color=\"#be4d25\">Mr. Hyde</font>, melee hits gain <font color=\"#77d914\">+100%</font> knockdown and stumble power."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConcussiveRoar'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_ConcussiveRoar_Deluxe'
	Name="Default__ZTUpgrade_Skill_ConcussiveRoar"
}
