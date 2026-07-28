// ===================================================================
// DKPawn_ZedGorefast_Omega_Puppet
//
// Puppet Master controllable variant of ZR's WMPawn_ZedGorefast_Omega (Case A).
// Gorefast skeleton -> reuses KFSM_PlayerGorefast_*. Control layer only.
// (WMPawn_ZedGorefast_Omega extends WMPawn_ZedGorefast_NoDualBlade -> still gorefast.)
// Stats/mesh/identity stay inherited.
// ===================================================================
class DKPawn_ZedGorefast_Omega_Puppet extends WMPawn_ZedGorefast_Omega;

defaultproperties
{
	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerGorefast_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerGorefast_Melee2'
		SpecialMoveClasses(SM_PlayerZedMove_V)=class'KFSM_PlayerGorefast_Melee3'
		SpecialMoveClasses(SM_PlayerZedMove_MMB)=class'KFSM_PlayerGorefast_Block'
	End Object

	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Block_R1)=SM_PlayerZedMove_MMB
	MoveListGamepadScheme(ZGM_Special_R3)=SM_PlayerZedMove_V

	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,	CooldownTime=0.26f,	SpecialMoveIcon=Texture2D'ZED_Gorefast_UI.ZED-VS_Icons_Gorefast-Melee', NameLocalizationKey="Light")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,	CooldownTime=0.52f,	SpecialMoveIcon=Texture2D'ZED_Gorefast_UI.ZED-VS_Icons_Gorefast-HeavyMelee', NameLocalizationKey="Heavy")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,				CooldownTime=0.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(3)=(SMHandle=SM_PlayerZedMove_V,	CooldownTime=1.27f,	SpecialMoveIcon=Texture2D'ZED_Gorefast_UI.ZED-VS_Icons_Gorefast-BladeSwing', NameLocalizationKey="Spin")
	SpecialMoveCooldowns(4)=(SMHandle=SM_PlayerZedMove_MMB,	CooldownTime=0.2f,	SpecialMoveIcon=Texture2D'ZED_Shared_UI.ZED-VS_Icons_Generic-Block', NameLocalizationKey="Block")
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,				CooldownTime=1.f,	SpecialMoveIcon=Texture2D'ZED_Gorefast_UI.ZED-VS_Icons_Gorefast-Jump', bShowOnHud=false))

	ThirdPersonViewOffset={(
		OffsetHigh=(X=-175,Y=50,Z=25),
		OffsetLow=(X=-220,Y=50,Z=50),
		OffsetMid=(X=-140,Y=50,Z=-10),
		)}
}
