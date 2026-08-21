class ZTZedBuff_Omen_SpawnRate extends WMZedBuff;

var float SpawnRate;

static function ModifySpawnRateMod(out float SpawnRateMod)
{
    SpawnRateMod += default.SpawnRate;
}

defaultproperties
{
    SpawnRate=0.05f

    bShouldLocalize=False
    BuffDescription="Omen: Spawn rate +5%"
    BuffIcon=Texture2D'ZedternalRBPerkpackage_Resources.Perks.UI_ZedBuff_Omen_SpawnRate'

    Name="Default__ZTZedBuff_Omen_SpawnRate"
}
