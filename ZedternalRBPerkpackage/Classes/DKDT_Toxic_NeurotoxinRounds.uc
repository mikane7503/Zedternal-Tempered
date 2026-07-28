class DKDT_Toxic_NeurotoxinRounds extends KFDT_Toxic
	abstract;

static function bool AlwaysPoisons()
{
	return true;
}

defaultproperties
{
	KDamageImpulse=0

	DoT_Type=DOT_Toxic
	DoT_Duration=200.0
	DoT_Interval=1.0
	DoT_DamageScale=1.0

	PoisonPower=50
}