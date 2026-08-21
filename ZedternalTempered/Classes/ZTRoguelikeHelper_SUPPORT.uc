/** "Walking Armory" - +1 grenade every 5 waves. */
class ZTRoguelikeHelper_SUPPORT extends ZTRoguelikeHelper;

var int WavesSinceGrenade;

function OnWaveStart(int WaveNum)
{
    local KFInventoryManager KFIM;

    WavesSinceGrenade++;
    if (WavesSinceGrenade >= 5 && OwnerPawn != None)
    {
        WavesSinceGrenade = 0;
        KFIM = KFInventoryManager(OwnerPawn.InvManager);
        if (KFIM != None)
        {
            KFIM.AddGrenades(1);
            `log("[DK_RL_SUPPORT] Walking Armory: +1 grenade");
        }
    }
}

defaultproperties
{
    WavesSinceGrenade=0
    Name="Default__ZTRoguelikeHelper_SUPPORT"
}
