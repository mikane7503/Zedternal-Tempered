class ZTUpgrade_Skill_IceArmor_Helper extends Info transient;

var KFPawn_Human Player;
var bool bDeluxe;
var int UpgradeLevel;
var float LastDamageTime;
var const float Update, OutOfCombatTime, RegenInterval;
var const int RegenAmount;
var float NextRegenTime;

function PostBeginPlay()
{
    super.PostBeginPlay();

    Player = KFPawn_Human(Owner);
    if (Player == None || Player.Health <= 0)
        Destroy();
    else
    {
        SetTimer(Update, True);
        LastDamageTime = Player.WorldInfo.TimeSeconds;
        NextRegenTime = Player.WorldInfo.TimeSeconds + RegenInterval;
    }
}

function Timer()
{
    local float CurrentTime;
    local int MaxArmor, CurrentArmor;

    if (Player == None || Player.Health <= 0)
    {
        Destroy();
        return;
    }

    CurrentTime = Player.WorldInfo.TimeSeconds;

    // Check if we should regenerate armor
    if ((CurrentTime - LastDamageTime) >= OutOfCombatTime && CurrentTime >= NextRegenTime)
    {
        // Calculate max armor (including ice armor bonus)
        MaxArmor = Player.MaxArmor + class'ZTUpgrade_Skill_IceArmor'.default.ArmorBonus[UpgradeLevel - 1];

        CurrentArmor = Player.Armor;

        // Regenerate armor if not at max
        if (CurrentArmor < MaxArmor)
        {
            Player.AddArmor(RegenAmount);
            NextRegenTime = CurrentTime + RegenInterval;
        }
    }
}

function OnDamageTaken()
{
    LastDamageTime = Player.WorldInfo.TimeSeconds;
}

defaultproperties
{
    bDeluxe=False
    UpgradeLevel=1
    Update=0.5f
    OutOfCombatTime=3.0f
    RegenInterval=3.0f
    RegenAmount=1
    LastDamageTime=0.0f
    NextRegenTime=0.0f

    Name="Default__ZTUpgrade_Skill_IceArmor_Helper"
}