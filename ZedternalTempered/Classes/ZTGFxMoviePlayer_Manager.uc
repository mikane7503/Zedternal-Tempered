// ===================================================================
// ZTGFxMoviePlayer_Manager - Override trader menu binding
// to use ZTGFxMenu_Trader
// ===================================================================
class ZTGFxMoviePlayer_Manager extends WMGFxMoviePlayer_Manager;

defaultproperties
{
	WidgetBindings(21)=(WidgetName="traderMenu",WidgetClass=Class'ZedternalTempered.ZTGFxMenu_Trader')

	Name="Default__ZTGFxMoviePlayer_Manager"
}
