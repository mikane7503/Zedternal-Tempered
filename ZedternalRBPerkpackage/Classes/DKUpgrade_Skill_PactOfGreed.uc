// Pact of Greed - universal luck: killing blows pay bonus dosh.
class DKUpgrade_Skill_PactOfGreed extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<int> DoshPerKill;
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DoshPerKill[0] = 1;
		default.DoshPerKill[1] = 2;
		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	if (MyKFPM == None || DamageInstigator == None || DamageInstigator.PlayerReplicationInfo == None)
		return;

	// Lethal hit: bank the pact's cut
	if (InDamage >= MyKFPM.Health && MyKFPM.Health > 0)
		KFPlayerReplicationInfo(DamageInstigator.PlayerReplicationInfo).AddDosh(default.DoshPerKill[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_PactOfGreed"

	UpgradeName="Pact of Greed"
	upgradeDescription(0)="Your killing blows pay <font color=\"#ffc832\">+1 bonus Dosh</font>."
	upgradeDescription(1)="Your killing blows pay <font color=\"#ffc832\">+2 bonus Dosh</font>."
	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_PactOfGreed'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_PactOfGreed_Deluxe'
	Name="Default__DKUpgrade_Skill_PactOfGreed"
}
