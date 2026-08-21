// Iron Palms - universal: reduced damage from zed projectiles and ranged attacks.
class ZTUpgrade_Skill_IronPalms extends ZTUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> RangedResist;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.RangedResist[0] = 0.20f;
		default.RangedResist[1] = 0.35f;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageTaken(out int InDamage, int DefaultDamage, int upgLevel, KFPawn OwnerPawn, optional class<DamageType> DamageType, optional Controller InstigatedBy, optional KFWeapon MyKFW)
{
	if (DamageType == None)
		return;

	// Zed ranged/projectile damage families: Husk fire, Bloat puke, Patriarch
	// rockets/gun, Hans nades/guns, Siren scream.
	if (ClassIsChildOf(DamageType, class'KFDT_Fire')
		|| ClassIsChildOf(DamageType, class'KFDT_Toxic')
		|| ClassIsChildOf(DamageType, class'KFDT_Ballistic')
		|| ClassIsChildOf(DamageType, class'KFDT_Explosive')
		|| ClassIsChildOf(DamageType, class'KFDT_Sonic'))
	{
		// Only when it came from a ZED, not environmental or player sources
		if (InstigatedBy != None && KFPawn_Monster(InstigatedBy.Pawn) != None)
			InDamage -= Round(float(DefaultDamage) * default.RangedResist[upgLevel - 1]);
	}
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalTempered"
	LocSection="ZTUpgrade_Skill_IronPalms"

	UpgradeName="Iron Palms"
	upgradeDescription(0)="Take <font color=\"#77d914\">20% less damage</font> from zed <font color=\"#15d7fa\">projectiles and ranged attacks</font>."
	upgradeDescription(1)="Take <font color=\"#77d914\">35% less damage</font> from zed <font color=\"#15d7fa\">projectiles and ranged attacks</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_IronPalms'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_IronPalms_Deluxe'
	Name="Default__ZTUpgrade_Skill_IronPalms"
}
