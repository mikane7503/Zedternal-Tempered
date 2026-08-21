/** "The Watcher's Gift" - 3% hit chance to terrify for four seconds. */
class ZTRoguelikeHelper_HAUNTED extends ZTRoguelikeHelper;

const TERRIFY_BONUS = 0.30;
const TERRIFY_CHANCE = 0.03;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    local ZTHauntedTerrifyMarker Marker;

    if (Target == None || !Target.IsAliveAndWell() || FRand() >= TERRIFY_CHANCE)
        return 0.0;

    foreach Target.ChildActors(class'ZTHauntedTerrifyMarker', Marker)
    {
        Marker.RefreshTerrify();
        return 0.0;
    }

    Marker = Target.Spawn(class'ZTHauntedTerrifyMarker', Target);
    if (Marker != None)
        Marker.Initialize(Target);

    return 0.0;
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_HAUNTED"
}
