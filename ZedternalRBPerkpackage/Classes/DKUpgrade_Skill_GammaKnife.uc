// ===================================================================
// DKUpgrade_Skill_GammaKnife - passive Domain skill.
//
// Zeds inside your Room take extra damage from you (Standard +25%,
// Deluxe +50%), on top of the perk's own in-room damage bonus. Reads
// the Domain helper's room state live in ModifyDamageGiven; needs no
// helper push. Does nothing without the Domain perk.
// ===================================================================
class DKUpgrade_Skill_GammaKnife extends DKUpgrade_Skill
	config(ZedternalUnlimited);

var config array<float> DamageBonus;    // [standard, deluxe] fraction of default damage
var config int MODEVERSION;

static function UpdateConfig()
{
	if (default.MODEVERSION < 1)
	{
		default.DamageBonus[0] = 0.25f;
		default.DamageBonus[1] = 0.50f;

		default.MODEVERSION = 1;
		static.StaticSaveConfig();
	}
}

static function ModifyDamageGiven(out int InDamage, int DefaultDamage, int upgLevel, optional Actor DamageCauser, optional KFPawn_Monster MyKFPM, optional KFPlayerController DamageInstigator, optional class<KFDamageType> DamageType, optional int HitZoneIdx, optional KFWeapon MyKFW)
{
	local DKUpgrade_Perk_Domain_Helper H;

	if (MyKFPM == None || DamageInstigator == None || DamageInstigator.Pawn == None)
		return;

	H = class'DKUpgrade_Perk_Domain'.static.FindHelper(DamageInstigator.Pawn);
	if (H != None && H.IsActorInRoom(MyKFPM))
		InDamage += Round(float(DefaultDamage) * default.DamageBonus[upgLevel - 1]);
}

defaultproperties
{
	bShouldLocalize=True
	LocPackage="ZedternalRBPerkpackage"
	LocSection="DKUpgrade_Skill_GammaKnife"

	UpgradeName="Gamma Knife"
	upgradeDescription(0)="Deal <font color=\"#77d914\">+25% damage</font> to zeds inside your <font color=\"#be4d25\">Room</font>."
	upgradeDescription(1)="Deal <font color=\"#77d914\">+50% damage</font> to zeds inside your <font color=\"#be4d25\">Room</font>."

	UpgradeIcon(0)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GammaKnife'
	UpgradeIcon(1)=Texture2D'ZedternalRBPerkpackage_Resources.Skills.UI_Skill_GammaKnife_Deluxe'

	Name="Default__DKUpgrade_Skill_GammaKnife"
}
