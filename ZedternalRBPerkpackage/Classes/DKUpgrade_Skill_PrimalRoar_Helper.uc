class DKUpgrade_Skill_PrimalRoar_Helper extends Info;

var KFPawn_Human Player;
var int KillCount;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();

    KillCount = 0;
}

function RegisterKill(int KillThreshold, int RadiusSq, int upgLevel)
{
    KillCount++;

    if (KillCount >= KillThreshold)
    {
        KillCount = 0;
        TriggerShockwave(RadiusSq, upgLevel);
    }
}

function TriggerShockwave(int RadiusSq, int upgLevel)
{
    local KFPawn_Monster KFM;
    local int EnemiesHit;
    local KFPlayerController KFPC;

    if (Player == None || Player.Health <= 0)
        return;

    EnemiesHit = 0;

    foreach DynamicActors(class'KFPawn_Monster', KFM)
    {
        if (KFM.IsAliveAndWell() && VSizeSQ(Player.Location - KFM.Location) <= RadiusSq)
        {
            if (upgLevel >= 2)
            {
                // Deluxe: Full knockdown
                if (KFM.CanDoSpecialMove(SM_Knockdown))
                    KFM.Knockdown(vect(0,0,0), vect(1,1,1), KFM.Location, 1000, 100);
                else if (KFM.CanDoSpecialMove(SM_Stumble))
                    KFM.DoSpecialMove(SM_Stumble, , , class'KFSM_Stumble'.static.PackRandomSMFlags(KFM));
            }
            else
            {
                // Standard: Stumble (knockdown as fallback for smaller zeds)
                if (KFM.CanDoSpecialMove(SM_Stumble))
                    KFM.DoSpecialMove(SM_Stumble, , , class'KFSM_Stumble'.static.PackRandomSMFlags(KFM));
            }

            EnemiesHit++;
        }
    }

    // Notify player
    KFPC = KFPlayerController(Player.Controller);
    if (KFPC != None)
    {
        if (EnemiesHit > 0)
            KFPC.ClientMessage("Primal Roar! " $ EnemiesHit $ " enemies hit!", 'Event');
        else
            KFPC.ClientMessage("Primal Roar! (No enemies in range)", 'Event');
    }
}

defaultproperties
{
    KillCount=0

    Name="Default__DKUpgrade_Skill_PrimalRoar_Helper"
}
