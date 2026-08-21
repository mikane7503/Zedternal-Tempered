// Follow Through - universal: bonus damage vs zeds that are down or airborne.
// Pairs with Fastball knockups, knockdown weapons, and explosive launches.
class ZTUpgrade_Skill_FollowThrough extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> DamageBonus;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DamageBonus[0] = 0.15f;
		default.DamageBonus[1] = 0.30f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (MyKFPM == None)
		return;

	// Knocked down (ragdoll), falling/launched, or incapacitated on the ground
	if (MyKFPM.Physics == PHYS_Falling
		|| MyKFPM.Physics == PHYS_RigidBody
		|| MyKFPM.IsIncapacitated())
	{
		InDamage += Round(float(DefaultDamage) * default.DamageBonus[upgLevel - 1]);
	}
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_FollowThrough"

	UpgradeName="Follow Through"
	upgradeDescription(0)="Deal <font color=\"#ff3399\">+15% damage</font> to zeds that are <font color=\"#15d7fa\">knocked down, airborne or incapacitated</font>."
	upgradeDescription(1)="Deal <font color=\"#ff3399\">+30% damage</font> to zeds that are <font color=\"#15d7fa\">knocked down, airborne or incapacitated</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FollowThrough'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_FollowThrough_Deluxe'
	Name="Default__ZTUpgrade_Skill_FollowThrough"
}
