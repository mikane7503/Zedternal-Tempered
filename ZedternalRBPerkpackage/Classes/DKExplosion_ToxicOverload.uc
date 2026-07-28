// Explosion actor for Toxic Overload.
// Uses Hans NerveGas template with custom toxic DamageType.
// Based on WMExplosion_Virus pattern.
class DKExplosion_ToxicOverload extends KFExplosion_PlayerCrawlerSuicide;

var const class<DamageType> DamageTypeClass;

function PostBeginPlay()
{
	local KFGameExplosion KFGExp;

	super.PostBeginPlay();
	ClientExplode();

	KFGExp = class'KFGameContent.KFPawn_ZedHans'.default.NerveGasAttackTemplate;
	KFGExp.MyDamageType = default.DamageTypeClass;
	Explode(KFGExp);
}

reliable client function ClientExplode()
{
	local KFGameExplosion KFGExp;

	KFGExp = class'KFGameContent.KFPawn_ZedHans'.default.NerveGasAttackTemplate;
	KFGExp.MyDamageType = default.DamageTypeClass;
	Explode(KFGExp);
}

defaultproperties
{
	DamageTypeClass=class'ZedternalRBPerkpackage.DKDT_ToxicOverload'

	interval=1.0f
	maxTime=5.0f

	Name="Default__DKExplosion_ToxicOverload"
}
