// ===================================================================
// DKGFxMenu_Trader - Override CreateUPGMenu to use DKUI_Menu
// ===================================================================
class DKGFxMenu_Trader extends WMGFxMenu_Trader;

function CreateUPGMenu()
{
	local DKUI_Menu UPGMenu;
	local WMPlayerController WMPC;

	WMPC = WMPlayerController(MyKFPC);
	if (WMPC == None || WMPC.bUpgradeMenuOpen)
		return;

	WMPC.bUpgradeMenuOpen = true;

	UPGMenu = new class'ZedternalRBPerkpackage.DKUI_Menu';
	UPGMenu.Owner = WMPawn_Human(WMPC.Pawn);
	UPGMenu.WMPC = WMPC;
	UPGMenu.WMPRI = WMPlayerReplicationInfo(WMPC.PlayerReplicationInfo);
	UPGMenu.SetTimingMode(TM_Real);
	UPGMenu.Init(LocalPlayer(WMPC.Player));
}

defaultproperties
{
	SubWidgetBindings(2)=(WidgetName="ShopContainer",WidgetClass=Class'ZedternalRBPerkpackage.DKGFxTraderContainer_Store')
	Name="Default__DKGFxMenu_Trader"
}
