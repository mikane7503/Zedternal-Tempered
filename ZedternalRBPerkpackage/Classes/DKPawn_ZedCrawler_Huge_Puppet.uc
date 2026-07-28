// ===================================================================
// DKPawn_ZedCrawler_Huge_Puppet
//
// Puppet Master controllable variant of ZR's WMPawn_ZedCrawler_Huge (Case A).
// Crawler skeleton -> reuses KFSM_PlayerCrawler_*. Control layer only.
// Stats/mesh/scale/identity stay inherited.
// ===================================================================
class DKPawn_ZedCrawler_Huge_Puppet extends WMPawn_ZedCrawler_Huge;

defaultproperties
{
	bVersusZed=true
	TeammateCollisionRadiusPercent=0.30

	Begin Object Name=SpecialMoveHandler_0
		SpecialMoveClasses(SM_PlayerZedMove_LMB)=class'KFSM_PlayerCrawler_Melee'
		SpecialMoveClasses(SM_PlayerZedMove_RMB)=class'KFSM_PlayerCrawler_Melee2'
		SpecialMoveClasses(SM_PlayerZedMove_G)=class'KFSM_PlayerCrawler_Suicide'
	End Object

	MoveListGamepadScheme(ZGM_Melee_Square)=SM_PlayerZedMove_LMB
	MoveListGamepadScheme(ZGM_Melee_Triangle)=SM_PlayerZedMove_RMB
	MoveListGamepadScheme(ZGM_Explosive_Ll)=SM_PlayerZedMove_G

	SpecialMoveCooldowns(0)=(SMHandle=SM_PlayerZedMove_LMB,	CooldownTime=0.65f,	SpecialMoveIcon=Texture2D'ZED_Crawler_UI.ZED-VS_Icons_Crawler-LightLeap', NameLocalizationKey="Light")
	SpecialMoveCooldowns(1)=(SMHandle=SM_PlayerZedMove_RMB,	CooldownTime=1.0f,	SpecialMoveIcon=Texture2D'ZED_Crawler_UI.ZED-VS_Icons_Crawler-HeavyLeap', NameLocalizationKey="Heavy")
	SpecialMoveCooldowns(2)=(SMHandle=SM_Taunt,				CooldownTime=0.0f,	bShowOnHud=false)
	SpecialMoveCooldowns(6)=(SMHandle=SM_PlayerZedMove_G,	CooldownTime=0.0f,	SpecialMoveIcon=Texture2D'ZED_Crawler_UI.ZED-VS_Icons_Crawler-Explode', NameLocalizationKey="Suicide")
	SpecialMoveCooldowns.Add((SMHandle=SM_Jump,				CooldownTime=0.85f,	SpecialMoveIcon=Texture2D'ZED_Crawler_UI.ZED-VS_Icons_Crawler-Jump', bShowOnHud=false))

	ThirdPersonViewOffset={(
		OffsetHigh=(X=-300,Y=60,Z=60),
		OffsetLow=(X=-220,Y=60,Z=25),
		OffsetMid=(X=-250,Y=60,Z=-30),
		)}
}
