// ===================================================================
// DEPRECATED - renamed to ZTUpgrade_Skill_FastHands.
//
// This stub exists for ONE release so the new class's UpdateConfig can
// carry over admin-tuned FireRateBonus values from the old INI section
// [ZedternalTempered.ZTUpgrade_Skill_QuickDraw]. It is not
// registered anywhere; old SkillPath entries pointing here are rewritten
// to the new class by the GameInfo boot migration. Safe to delete the
// release after next.
// ===================================================================
class ZTUpgrade_Skill_QuickDraw extends Object
	config(ZedternalUnlimited);

var config array<float> FireRateBonus;
var config int MODEVERSION;

defaultproperties
{
	Name="Default__ZTUpgrade_Skill_QuickDraw"
}
