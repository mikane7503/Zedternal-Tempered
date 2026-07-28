// ===================================================================
// DKPawn_ZedFleshpound_Omega_Puppet
//
// Puppet Master controllable variant of ZR's WMPawn_ZedFleshpound_Omega (Case A).
// Fleshpound skeleton -> reuses the stock Fleshpound player kit
// (KFSM_PlayerFleshpound_Melee / _Melee2 / _Rage / _Block). Control layer only,
// copied from KFPawn_ZedFleshPound_Versus; the rage-bump AoE / auto-end-rage
// override functions are skipped (polish - Rage still enrages via base SetEnraged).
// Stats/mesh/identity stay inherited.
// ===================================================================
class DKPawn_ZedFleshpound_Omega_Puppet extends WMPawn_ZedFleshpound_Omega;

defaultproperties
{
	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerFleshpound_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerFleshpound_Melee2'
		SpecialMoveClasses(SM_PlayerZedMove_V)=class'KFSM_PlayerFleshpound_Rage'
		SpecialMoveClasses(SM_PlayerZedMove_MMB)=class'KFSM_PlayerFleshpound_Block'
	End Object

	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Block_R1)=SM_PlayerZedMove_MMB
	MoveListGamepadScheme(ZGM_Special_R3)=SM_PlayerZedMove_V

	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,	CooldownTime=0.75f,	SpecialMoveIcon=Texture2D'ZED_Fleshpound_UI.ZED-VS_Icons_Fleshpound-LightAttack', NameLocalizationKey="Light")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,	CooldownTime=1.5f,	SpecialMoveIcon=Texture2D'ZED_Fleshpound_UI.ZED-VS_Icons_Fleshpound-HeavyAttack', NameLocalizationKey="Heavy")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,				CooldownTime=0.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(3)=(SMHandle=SM_PlayerZedMove_V,	CooldownTime=10.5f,	SpecialMoveIcon=Texture2D'ZED_Fleshpound_UI.ZED-VS_Icons_Fleshpound-Rage', NameLocalizationKey="Rage")
	SpecialMoveCooldowns(4)=(SMHandle=SM_PlayerZedMove_MMB,	CooldownTime=0.2,	SpecialMoveIcon=Texture2D'ZED_Shared_UI.ZED-VS_Icons_Generic-Block', NameLocalizationKey="Block")
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,				CooldownTime=1.25f,	SpecialMoveIcon=Texture2D'ZED_Fleshpound_UI.ZED-VS_Icons_Fleshpound-Jump', bShowOnHud=false))

	ThirdPersonViewOffset={(
		OffsetHigh=(X=-175,Y=60,Z=60),
		OffsetLow=(X=-220,Y=100,Z=50),
		OffsetMid=(X=-160,Y=50,Z=30),
		)}
}
