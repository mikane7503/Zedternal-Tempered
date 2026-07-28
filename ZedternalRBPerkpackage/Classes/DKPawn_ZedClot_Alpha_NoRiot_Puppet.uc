// ===================================================================
// DKPawn_ZedClot_Alpha_NoRiot_Puppet
//
// Puppet Master controllable variant of ZR's WMPawn_ZedClot_Alpha_NoRiot (Case A).
// It rides the Alpha-clot skeleton, so it reuses the stock Alpha player kit
// (KFSM_PlayerAlpha_Melee / _Grab / _Rally) for free. This subclass adds ONLY
// the player-control layer copied from KFPawn_ZedClot_Alpha_Versus; all
// stats / mesh / identity stay inherited from the custom zed.
// ===================================================================
class DKPawn_ZedClot_Alpha_NoRiot_Puppet extends WMPawn_ZedClot_Alpha_NoRiot;

defaultproperties
{
	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30
	bWeakZedGrab=false

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerAlpha_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerAlpha_Grab'
		SpecialMoveClasses(SM_PlayerZedMove_V)=class'KFSM_PlayerAlpha_Rally'
	End Object

	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Special_R3)=SM_PlayerZedMove_V

	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,	CooldownTime=0.18f,	SpecialMoveIcon=Texture2D'ZED_Clot_UI.ZED-VS_Icons_AlphaClot-Melee', NameLocalizationKey="Melee")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,	CooldownTime=0.0f,	SpecialMoveIcon=Texture2D'ZED_Clot_UI.ZED-VS_Icons_AlphaClot-Grab', NameLocalizationKey="Grab")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,				CooldownTime=0.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(3)=(SMHandle=SM_PlayerZedMove_V,	CooldownTime=1.5f,	SpecialMoveIcon=Texture2D'ZED_Clot_UI.ZED-VS_Icons_AlphaClot-Enrage', NameLocalizationKey="Rally")
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,				CooldownTime=1.f,	SpecialMoveIcon=Texture2D'ZED_Clot_UI.ZED-VS_Icons_AlphaClot-Jump', bShowOnHud=false))

	ThirdPersonViewOffset={(
		OffsetHigh=(X=-140,Y=50,Z=0),
		OffsetLow=(X=-220,Y=50,Z=50),
		OffsetMid=(X=-160,Y=50,Z=0),
		)}
}
