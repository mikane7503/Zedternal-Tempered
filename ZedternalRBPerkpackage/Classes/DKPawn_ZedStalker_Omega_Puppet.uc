// ===================================================================
// DKPawn_ZedStalker_Omega_Puppet
//
// Puppet Master controllable variant of ZR's WMPawn_ZedStalker_Omega (Case A).
// Stalker skeleton -> reuses KFSM_PlayerStalker_*. Control layer only.
// Stats/mesh/identity stay inherited.
// ===================================================================
class DKPawn_ZedStalker_Omega_Puppet extends WMPawn_ZedStalker_Omega;

defaultproperties
{
	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerStalker_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerStalker_Melee2'
		SpecialMoveClasses(SM_PlayerZedMove_V)=class'KFSM_PlayerStalker_Roll'
	End Object

	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Special_R3)=SM_PlayerZedMove_V

	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,	CooldownTime=0.25f,	SpecialMoveIcon=Texture2D'ZED_Stalker_UI.ZED-VS_Icons_Stalker-Melee', NameLocalizationKey="Light")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,	CooldownTime=1.0f,	SpecialMoveIcon=Texture2D'ZED_Stalker_UI.ZED-VS_Icons_Stalker-HeavyMelee', NameLocalizationKey="Heavy")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,				CooldownTime=0.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(3)=(SMHandle=SM_PlayerZedMove_V,	CooldownTime=0.35f,	SpecialMoveIcon=Texture2D'ZED_Stalker_UI.ZED-VS_Icons_Stalker-Evade', NameLocalizationKey="Evade")
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,				CooldownTime=1.0f,	SpecialMoveIcon=Texture2D'ZED_Stalker_UI.ZED-VS_Icons_Stalker-Jump', bShowOnHud=false))

	ThirdPersonViewOffset={(
		OffsetHigh=(X=-175,Y=50,Z=25),
		OffsetLow=(X=-220,Y=50,Z=50),
		OffsetMid=(X=-150,Y=50,Z=-30),
		)}
}
