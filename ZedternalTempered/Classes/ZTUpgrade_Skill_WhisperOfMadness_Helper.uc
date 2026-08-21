// ===================================================================
// ZTUpgrade_Skill_WhisperOfMadness_Helper
//
// Every 3rd wave, the prophecy condition is completely hidden.
// The HUD card shows only "???" with no information about the rule.
//
// If completed while hidden:
//   Standard: 2x blessing reward
//   Deluxe:   3x blessing reward
//
// If doomed while hidden:
//   Standard: 1.5x doom penalty
//   Deluxe:   1x doom penalty (normal doom)
// ===================================================================
class ZTUpgrade_Skill_WhisperOfMadness_Helper extends ZTUpgrade_Skill_OmenBase_Helper transient;

var int WaveCounter;       // Incremented each wave start
var bool bHiddenThisWave;  // True if the current wave is a hidden prophecy wave

function OnWaveStart(KFPawn_Human P)
{
    WaveCounter++;
    bHiddenThisWave = (WaveCounter % 3 == 0);

    `log("[DK_OMEN_SKILL] Whisper of Madness: Wave" @ WaveCounter @ "Hidden:" @ bHiddenThisWave @ "Level:" @ SkillLevel);
}

function bool ShouldHideProphecy()
{
    return bHiddenThisWave;
}

function float GetRewardMultiplier()
{
    if (bHiddenThisWave)
    {
        if (SkillLevel >= 2)
            return 3.0f;
        else
            return 2.0f;
    }

    return 1.0f;
}

function float GetDoomMultiplier()
{
    if (bHiddenThisWave)
    {
        if (SkillLevel >= 2)
            return 1.0f;   // Deluxe: normal doom
        else
            return 1.5f;   // Standard: 1.5x doom
    }

    return 1.0f;
}

defaultproperties
{
    WaveCounter=0
    bHiddenThisWave=false

    Name="Default__ZTUpgrade_Skill_WhisperOfMadness_Helper"
}
