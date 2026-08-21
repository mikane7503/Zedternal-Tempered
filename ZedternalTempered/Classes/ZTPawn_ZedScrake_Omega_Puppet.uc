// ===================================================================
// ZTPawn_ZedScrake_Omega_Puppet
//
// Puppet Master controllable variant of ZR's WMPawn_ZedScrake_Omega (Case A).
// Scrake skeleton -> reuses KFSM_PlayerScrake_* (Melee/Melee2/Melee3/Block).
// Control layer only; stats/mesh/identity stay inherited.
// ===================================================================
class ZTPawn_ZedScrake_Omega_Puppet extends WMPawn_ZedScrake_Omega;

defaultproperties
{
	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerScrake_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerScrake_Melee2'
		SpecialMoveClasses(SM_PlayerZedMove_V)=class'KFSM_PlayerScrake_Melee3'
		SpecialMoveClasses(SM_PlayerZedMove_MMB)=class'KFSM_PlayerScrake_Block'
	End Object

	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Block_R1)=SM_PlayerZedMove_MMB
	MoveListGamepadScheme(ZGM_Special_R3)=SM_PlayerZedMove_V

	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,	CooldownTime=0.5f,	SpecialMoveIcon=Texture2D'ZED_Scrake_UI.ZED-VS_Icons_Scrake-LightLunge', NameLocalizationKey="Light")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,	CooldownTime=1.5f,	SpecialMoveIcon=Texture2D'ZED_Scrake_UI.ZED-VS_Icons_Scrake-HeavyLunge', NameLocalizationKey="Heavy")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,				CooldownTime=1.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(3)=(SMHandle=SM_PlayerZedMove_V,	CooldownTime=2.5f,	SpecialMoveIcon=Texture2D'ZED_Scrake_UI.ZED-VS_Icons_Scrake-SpinAttack', NameLocalizationKey="Spin")
	SpecialMoveCooldowns(4)=(SMHandle=SM_PlayerZedMove_MMB,	CooldownTime=0.2,	SpecialMoveIcon=Texture2D'ZED_Shared_UI.ZED-VS_Icons_Generic-Block', NameLocalizationKey="Block")
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,				CooldownTime=1.25f,	SpecialMoveIcon=Texture2D'ZED_Scrake_UI.ZED-VS_Icons_Scrake-Jump', bShowOnHud=false))

	ThirdPersonViewOffset={(
		OffsetHigh=(X=-175,Y=60,Z=60),
		OffsetLow=(X=-220,Y=100,Z=50),
		OffsetMid=(X=-160,Y=50,Z=0),
		)}
}
