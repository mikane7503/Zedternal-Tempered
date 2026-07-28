// ===================================================================
// DKPawn_ZedClot_Slasher_Omega_Puppet
//
// Puppet Master controllable variant of ZR's WMPawn_ZedClot_Slasher_Omega (Case A).
// Rides the Slasher skeleton -> reuses the stock Slasher player kit
// (KFSM_PlayerSlasher_Melee / _Melee2 / _Roll). Control layer only, copied from
// KFPawn_ZedClot_Slasher_Versus; the mega-jump override functions are skipped
// (polish only - normal jump otherwise). Stats/mesh/identity stay inherited.
// ===================================================================
class DKPawn_ZedClot_Slasher_Omega_Puppet extends WMPawn_ZedClot_Slasher_Omega;

defaultproperties
{
	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_GrappleAttack)=none
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerSlasher_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerSlasher_Melee2'
		SpecialMoveClasses(SM_PlayerZedMove_V)=class'KFSM_PlayerSlasher_Roll'
	End Object

	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Special_R3)=SM_PlayerZedMove_V

	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,	CooldownTime=0.25f,	SpecialMoveIcon=Texture2D'ZED_Slasher_UI.ZED-VS_Icons_Slasher-Melee', NameLocalizationKey="Light")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,	CooldownTime=1.0f,	SpecialMoveIcon=Texture2D'ZED_Slasher_UI.ZED-VS_Icons_Slasher-HeavyMelee', NameLocalizationKey="Heavy")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,				CooldownTime=0.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(3)=(SMHandle=SM_PlayerZedMove_V,	CooldownTime=0.2f,	SpecialMoveIcon=Texture2D'ZED_Slasher_UI.ZED-VS_Icons_Slasher-Evade', NameLocalizationKey="Evade")
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,				CooldownTime=1.0f,	SpecialMoveIcon=Texture2D'ZED_Slasher_UI.ZED-VS_Icons_Slasher-Jump', bShowOnHud=false))

	ThirdPersonViewOffset={(
		OffsetHigh=(X=-175,Y=50,Z=0),
		OffsetLow=(X=-220,Y=50,Z=0),
		OffsetMid=(X=-145,Y=50,Z=-30),
		)}
}
