// ===================================================================
// DEPRECATED - renamed to DKUpgrade_Skill_EagleEye.
//
// This stub exists for ONE release so the new class's UpdateConfig can
// carry over admin-tuned HeadshotDamageBonus values from the old INI
// section [ZedternalRBPerkpackage.DKUpgrade_Skill_DeadEye]. It is not
// registered anywhere; old SkillPath entries pointing here are rewritten
// to the new class by the GameInfo boot migration. Safe to delete the
// release after next.
// ===================================================================
class DKUpgrade_Skill_DeadEye extends Object
	config(ZedternalUnlimited);

var config array<float> HeadshotDamageBonus;
var config int MODEVERSION;

defaultproperties
{
	Name="Default__DKUpgrade_Skill_DeadEye"
}
