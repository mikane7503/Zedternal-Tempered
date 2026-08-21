// ===================================================================
// ZTUI_Menu - DK fork of ZedternalReborn's WMUI_Menu (trader upgrade menu)
//
// Thin subclass: identical to WMUI_Menu in every respect EXCEPT that it
// rebinds the InventoryMenu Flash widget to ZTUI_UPGMenu instead of
// WMUI_UPGMenu. ZTUI_UPGMenu uses the paged perk helpers (GetPerkLevel /
// IsPerkUnlocked / SetPerkLevel) so perks at index >= 256 are visible and
// buyable through the upgrade menu - the stock WMUI_UPGMenu reads
// bPerkUpgrade[i] directly, which is an out-of-bounds read for i >= 256.
//
// Everything else - the LoaderManager movie, the confirmation popup, input
// handling, CloseMenu - is inherited unchanged from WMUI_Menu.
// ===================================================================
class ZTUI_Menu extends WMUI_Menu;

defaultproperties
{
	// Rebind only the inventory menu to the DK upgrade-menu fork; keep the
	// stock root manager and confirmation popup bindings exactly as WMUI_Menu
	// declares them. Empty first so we REPLACE the inherited
	// InventoryMenu->WMUI_UPGMenu binding instead of adding a duplicate.
	WidgetBindings.Empty
	WidgetBindings.Add((WidgetName="root1",WidgetClass=Class'GFxUI.GFxObject'))
	WidgetBindings.Add((WidgetName="InventoryMenu",WidgetClass=Class'ZedternalTempered.ZTUI_UPGMenu'))
	WidgetBindings.Add((WidgetName="ConfirmationPopup",WidgetClass=Class'ZedternalReborn.WMGFxObject_UPGMenuPopup'))
}
