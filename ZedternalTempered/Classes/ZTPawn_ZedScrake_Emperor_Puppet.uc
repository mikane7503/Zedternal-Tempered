// ===================================================================
// ZTPawn_ZedScrake_Emperor_Puppet
//
// Puppet Master CONTROLLABLE variant of ZR's Scrake Emperor (Case A).
//
// WMPawn_ZedScrake_Emperor extends KFPawn_ZedScrake, so it carries the stock
// Scrake skeleton + AnimSet. That means every KFSM_PlayerScrake_* player anim
// already exists on this mesh, so we can reuse the entire vanilla Scrake player
// kit for free - no new ability code. This subclass only ADDS the player-control
// layer (the same block KFPawn_ZedScrake_Versus adds over KFPawn_ZedScrake):
//   - bVersusZed=true                      -> player skin, blocks re-takeover, gates off AI logic
//   - SpecialMoveHandler.SpecialMoveClasses -> LMB/RMB/V melee + MMB block bindings
//   - SpecialMoveCooldowns                  -> the HUD ability tray + cooldown data
//   - MoveListGamepadScheme                 -> pad bindings
//   - ThirdPersonViewOffset                 -> chase cam
// Everything else (Health, rage, incap, mesh, DoshValue, the Emperor's own
// buffs/identity) is INHERITED unchanged from WMPawn_ZedScrake_Emperor.
//
// NOTE vs the Patriarch puppet: that one extended an existing _Versus parent and
// inherited the control layer; here there is no Scrake_Emperor_Versus, so we add
// the layer ourselves onto the AI-base custom zed. Prove this possesses cleanly
// in-game (abilities fire, HUD tray shows, clean revert) before stamping the
// pattern across the rest of the Case A roster.
//
// Scrake is melee/block only - no gun - so no bNeedsCrosshair / DefaultInventory.
// ===================================================================
class ZTPawn_ZedScrake_Emperor_Puppet extends WMPawn_ZedScrake_Emperor;

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
