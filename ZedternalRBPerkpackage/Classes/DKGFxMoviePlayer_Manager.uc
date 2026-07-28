// ===================================================================
// DKGFxMoviePlayer_Manager - Override trader menu binding
// to use DKGFxMenu_Trader
// ===================================================================
class DKGFxMoviePlayer_Manager extends WMGFxMoviePlayer_Manager;

defaultproperties
{
	WidgetBindings(21)=(WidgetName="traderMenu",WidgetClass=Class'ZedternalRBPerkpackage.DKGFxMenu_Trader')

	Name="Default__DKGFxMoviePlayer_Manager"
}
