/** "Paradox Anchor" - On death rewind 10s: restore HP and position. Once/wave. */
class DKRoguelikeHelper_TIMETRAVELER extends DKRoguelikeHelper;

var bool bUsedThisWave;
var vector SavedLocation;
var int SavedHealth;

function Initialize(KFPawn_Human InPawn)
{
    super.Initialize(InPawn);
    SetTimer(10.0, true, 'SaveState');
}

function SaveState()
{
    if (OwnerPawn != None && OwnerPawn.IsAliveAndWell())
    {
        SavedLocation = OwnerPawn.Location;
        SavedHealth = OwnerPawn.Health;
    }
}

function ModifyIncomingDamage(out int InDamage, int DefaultDamage, KFPawn OwnerP, class<DamageType> DamageType)
{
    local KFPawn_Human KFPH;

    KFPH = KFPawn_Human(OwnerP);
    if (KFPH == None)
        return;

    if (!bUsedThisWave && (KFPH.Health - InDamage) <= 0)
    {
        bUsedThisWave = true;
        InDamage = KFPH.Health - Max(SavedHealth, 1);
        if (InDamage < 0)
            InDamage = 0;
        KFPH.Health = Max(SavedHealth, 1);
        KFPH.SetLocation(SavedLocation);
        `log("[DK_RL_TIMETRAVELER] Paradox Anchor: REWOUND!");
    }
}

function OnWaveStart(int WaveNum)
{
    bUsedThisWave = false;
}

function Cleanup()
{
    ClearTimer('SaveState');
    super.Cleanup();
}

defaultproperties
{
    bUsedThisWave=false
    SavedHealth=100
    Name="Default__DKRoguelikeHelper_TIMETRAVELER"
}
