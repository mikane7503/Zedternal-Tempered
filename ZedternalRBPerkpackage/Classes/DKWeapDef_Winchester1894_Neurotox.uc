class DKWeapDef_Winchester1894_Neurotox extends KFWeaponDefinition
    abstract;
 
static function string GetItemName()
{
    return "Winchester 1894 Neurotox";
}
 
static function string GetItemDescription()
{
    return "A standard Winchester Rifle loaded with Neurotoxin bullets. Highly poisonous.";
}
 
defaultproperties
{
	WeaponClassPath="ZedternalRBPerkpackage.DKWeap_Rifle_Winchester1894_Neurotox"
	BuyPrice=800
	AmmoPricePerMag=120
	ImagePath="Texture2D'ZedternalRBPerkpackage_Resources.Weapons.UI_WeaponSelect_WinchesterNeurotox'"
	Name="Default__DKWeapDef_Winchester1894_Neurotox"
}