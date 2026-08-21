// ===================================================================
// ZTGFxMenu_Trader - Override CreateUPGMenu to use ZTUI_Menu
// ===================================================================
class ZTGFxMenu_Trader extends WMGFxMenu_Trader;

function CreateUPGMenu()
{
	local ZTUI_Menu UPGMenu;
	local WMPlayerController WMPC;

	WMPC = WMPlayerController(MyKFPC);
	if (WMPC == None || WMPC.bUpgradeMenuOpen)
		return;

	WMPC.bUpgradeMenuOpen = true;

	UPGMenu = new class'ZedternalTempered.ZTUI_Menu';
	UPGMenu.Owner = WMPawn_Human(WMPC.Pawn);
	UPGMenu.WMPC = WMPC;
	UPGMenu.WMPRI = WMPlayerReplicationInfo(WMPC.PlayerReplicationInfo);
	UPGMenu.SetTimingMode(TM_Real);
	UPGMenu.Init(LocalPlayer(WMPC.Player));
}

defaultproperties
{
	SubWidgetBindings(2)=(WidgetName="ShopContainer",WidgetClass=Class'ZedternalTempered.ZTGFxTraderContainer_Store')
	Name="Default__ZTGFxMenu_Trader"
}
