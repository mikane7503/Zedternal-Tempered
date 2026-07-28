// ===================================================================
// DKUI_UPGMenu - DK fork of ZedternalReborn's WMUI_UPGMenu
// ===================================================================
// Fork strategy: SUBCLASS with surgical overrides. Everything not listed
// below is inherited verbatim from WMUI_UPGMenu so ZR balance/list changes
// keep flowing through. Overridden functions (each = parent body + a guard
// or addition, documented inline):
//
//   BuildPerkUpgradeList     - PAGED: GetPerkLevel/IsPerkUnlocked replace the
//                              direct WMPRI.bPerkUpgrade[i] reads (OOB >=256),
//                              plus the "hide non-owned perks at the perk cap"
//                              display filter.
//   BuildSkillUpgradeList    - Super (normal rows) + appended on-demand Deluxe
//                              upgrade action rows (targeted or random).
//   Callback_Equip           - PAGED perk buy + Deluxe-row dispatch to the
//                              server RPCs; every other tab is parent-verbatim.
//   CallBack_ItemDetailsClicked - PAGED perk price + Deluxe-row price label.
//   SkillRerollUnlock        - PAGED: GetPerkLevel replaces bPerkUpgrade level.
//   BuildWeaponUpgradeList   - parent body + Hollow skill gate.
//
// NOTE: this menu deliberately has NO search/name-filter UI. That experiment
// was rolled back; do not re-add a filter widget here.
//
// Server side of the Deluxe upgrade lives in DKPlayerController
// (ServerBuyDeluxeUpgrade / ServerBuyDeluxeUpgradeRandom) and the gating
// settings replicate via DKGameReplicationInfo (bDeluxeUpgradeEnabled,
// DeluxeMinPerkLevel, DeluxeUpgradeCost, bDeluxeTargetedSelection).
// ===================================================================
class DKUI_UPGMenu extends WMUI_UPGMenu;

// On-demand Deluxe upgrade action rows are appended AFTER the normal skill
// rows in the skill tab. Each appended row's displayed "definition" is
// (SkillUPGIndex.Length + index-into-DeluxeRows). Callback_Equip /
// CallBack_ItemDetailsClicked use that offset to recognise and dispatch them.
struct DeluxeRowInfo
{
	var bool bRandom;     // True  => random per-perk  (ServerBuyDeluxeUpgradeRandom, TargetIndex = perk index)
	                      // False => targeted skill   (ServerBuyDeluxeUpgrade,        TargetIndex = skill index)
	var int  TargetIndex;
};
var array<DeluxeRowInfo> DeluxeRows;

var string DeluxeTargetedSuffix;
var string DeluxeRandomPrefix;
var string DeluxeRandomDescription;

// ===================================================================
// PERK UPGRADE LIST - parent body verbatim with two changes:
//  (1) PAGED: IsPerkUnlocked / GetPerkLevel replace the direct
//      WMPRI.bPerkUpgrade[i] reads, which OOB to 0 for paged perks (>=256).
//  (2) QOL: once the player is at the different-perks cap and so cannot
//      take a brand-new perk, perks they do not yet own are hidden.
// ===================================================================
function BuildPerkUpgradeList(out GFxObject ItemArray)
{
	local bool bPurchased;
	local GFxObject ItemObject;
	local int i, x, lvl, MaxLevel, TempPrice;
	local string S;
	local DKPlayerReplicationInfo DKPRI;
	local DKGameReplicationInfo DKGRI;
	local int OwnedDifferent;
	local bool bAtPerkCap;

	DKPRI = DKPlayerReplicationInfo(WMPRI);
	DKGRI = DKGameReplicationInfo(WMGRI);

	// Defensive: if the DK cast fails (should never happen in this game mode),
	// fall back to the parent so the list still builds for indices < 256.
	if (DKPRI == None)
	{
		Super.BuildPerkUpgradeList(ItemArray);
		return;
	}

	PerkUPGIndex.Length = 0;
	x = 0;

	// QOL: at the different-perks cap, hide perks the player does not own yet.
	// "Owned" = at least one level. MaxDifferentPerks == 0 means no cap.
	bAtPerkCap = False;
	if (DKGRI != None && DKGRI.MaxDifferentPerks > 0)
	{
		OwnedDifferent = 0;
		for (i = 0; i < WMGRI.PerkUpgradesList.Length; ++i)
		{
			if (DKPRI.GetPerkLevel(i) > 0)
				++OwnedDifferent;
		}
		bAtPerkCap = (OwnedDifferent >= DKGRI.MaxDifferentPerks);
	}

	for (i = 0; i < WMGRI.PerkUpgradesList.Length; ++i)
	{
		// PAGED: IsPerkUnlocked replaces WMPRI.bPerkUpgrade[i].bUnlocked.
		if (DKPRI.IsPerkUnlocked(i))
		{
			// QOL: at cap, skip perks the player does not own yet.
			if (bAtPerkCap && DKPRI.GetPerkLevel(i) == 0)
				continue;

			// PAGED: GetPerkLevel replaces WMPRI.bPerkUpgrade[i].level.
			lvl = DKPRI.GetPerkLevel(i);

			// Get Max Level of that upgrade
			MaxLevel = WMGRI.PerkUpgMaxLevel;

			// Is it fully bought?
			if (lvl >= MaxLevel)
				bPurchased = True;
			else
				bPurchased = False;

			// Create info arch
			if ((CurrentUpgradeFilter == EWMInv_All) || (CurrentUpgradeFilter == EWMInv_Available && !bPurchased) || (CurrentUpgradeFilter == EWMInv_Purchased && bPurchased))
			{
				if (bPurchased)
					--lvl;

				ItemObject = CreateObject("Object");

				TempPrice = WMGRI.PerkUpgPrice[lvl];
				ItemObject.SetInt("count", TempPrice);

				if (WMGRI.PerkUpgradesList[i].PerkUpgrade.default.bShouldLocalize)
					S = WMGRI.PerkUpgradesList[i].PerkUpgrade.static.GetUpgradeName();
				else
					S = WMGRI.PerkUpgradesList[i].PerkUpgrade.default.UpgradeName;

				if (MaxLevel > 1)
				{
					if (bPurchased)
						S @= "(" $MaxLevel $"/" $MaxLevel $")";
					else
						S @= "(" $lvl $"/" $MaxLevel $")";
				}

				ItemObject.SetString("label", S);
				ItemObject.SetString("price", "");
				ItemObject.Setstring("typeRarity", "");
				ItemObject.SetBool("exchangeable", False);
				ItemObject.SetBool("recyclable", WMGRI.bAllowSkillReroll ? lvl > 0 : False);
				ItemObject.SetInt("definition", x);
				if (bPurchased)
				{
					ItemObject.SetInt("type", 1);
					ItemObject.SetBool("active", True);
					ItemObject.SetInt("rarity", 0);
				}
				else
				{
					if (WMPRI.Score < TempPrice)
						ItemObject.SetInt("type", 1);
					else
						ItemObject.SetInt("type", 0);

					ItemObject.SetBool("active", False);
				}
				S = "img://"$PathName(WMGRI.PerkUpgradesList[i].PerkUpgrade.static.GetUpgradeIcon(lvl));
				ItemObject.SetString("description", GetPerkDescription(i, lvl));
				ItemObject.SetString("iconURLSmall", S);
				ItemObject.SetString("iconURLLarge", S);
				ItemArray.SetElementObject(x, ItemObject);
				PerkUPGIndex.AddItem(i);
				++x;
			}
		}
	}
}

// ===================================================================
// SKILL UPGRADE LIST - parent body via Super (normal skill rows +
// SkillUPGIndex), then append on-demand Deluxe upgrade action rows.
//
//   bDeluxeTargetedSelection == True : one row per eligible owned non-Deluxe
//       skill (player picks the exact skill -> ServerBuyDeluxeUpgrade).
//   bDeluxeTargetedSelection == False: one row per eligible perk that has at
//       least one eligible owned non-Deluxe skill (server rolls one ->
//       ServerBuyDeluxeUpgradeRandom).
//
// Eligibility mirrors the server (DKPlayerController.IsDeluxeSkillEligible):
// skill owned & not Deluxe (GetSkillUpgrade == 1) and owning perk level
// >= DeluxeMinPerkLevel. Rows are appended past the normal skill rows; their
// definition index is (SkillUPGIndex.Length + DeluxeRows index).
// ===================================================================
function BuildSkillUpgradeList(out GFxObject ItemArray)
{
	local DKGameReplicationInfo DKGRI;
	local DKPlayerReplicationInfo DKPRI;
	local GFxObject ItemObject;
	local int i, x, perkIdx, TempPrice;
	local string S;
	local DeluxeRowInfo RowInfo;

	// Normal skill rows + SkillUPGIndex population (parent body, unchanged).
	Super.BuildSkillUpgradeList(ItemArray);

	DeluxeRows.Length = 0;

	DKGRI = DKGameReplicationInfo(WMGRI);
	DKPRI = DKPlayerReplicationInfo(WMPRI);
	if (DKGRI == None || DKPRI == None || !DKGRI.bDeluxeUpgradeEnabled)
		return;

	// A Deluxe conversion is an available action, not a purchased item, so it
	// shows under All / Available and never under Purchased.
	if (CurrentUpgradeFilter == EWMInv_Purchased)
		return;

	x = SkillUPGIndex.Length;
	TempPrice = DKGRI.DeluxeUpgradeCost;

	if (DKGRI.bDeluxeTargetedSelection)
	{
		// Targeted: one row per eligible owned, non-Deluxe skill.
		for (i = 0; i < DKGRI.SkillUpgradesList.Length; ++i)
		{
			if (WMPRI.GetSkillUpgrade(i) != 1)   // 1 = owned, not Deluxe
				continue;

			perkIdx = GetPerkRelatedIndex(i);
			if (DKPRI.GetPerkLevel(perkIdx) < DKGRI.DeluxeMinPerkLevel)
				continue;

			ItemObject = CreateObject("Object");

			if (WMGRI.SkillUpgradesList[i].SkillUpgrade.default.bShouldLocalize)
				S = WMGRI.SkillUpgradesList[i].SkillUpgrade.static.GetUpgradeName();
			else
				S = WMGRI.SkillUpgradesList[i].SkillUpgrade.default.UpgradeName;

			ItemObject.SetString("label", S @default.DeluxeTargetedSuffix);

			if (WMGRI.SkillUpgradesList[i].SkillUpgrade.default.bShouldLocalize)
				ItemObject.SetString("description", WMGRI.SkillUpgradesList[i].SkillUpgrade.static.GetUpgradeDescription(True));
			else
				ItemObject.SetString("description", WMGRI.SkillUpgradesList[i].SkillUpgrade.default.UpgradeDescription[1]);

			S = "img://"$PathName(WMGRI.SkillUpgradesList[i].SkillUpgrade.static.GetUpgradeIcon(1));
			ItemObject.SetString("iconURLSmall", S);
			ItemObject.SetString("iconURLLarge", S);

			FillDeluxeRowCommon(ItemObject, x, TempPrice);

			RowInfo.bRandom = False;
			RowInfo.TargetIndex = i;
			DeluxeRows.AddItem(RowInfo);

			ItemArray.SetElementObject(x, ItemObject);
			++x;
		}
	}
	else
	{
		// Random: one row per eligible perk that has an eligible owned skill.
		for (perkIdx = 0; perkIdx < DKGRI.PerkUpgradesList.Length; ++perkIdx)
		{
			if (DKPRI.GetPerkLevel(perkIdx) < DKGRI.DeluxeMinPerkLevel)
				continue;
			if (!PerkHasEligibleDeluxeSkill(DKGRI, perkIdx))
				continue;

			ItemObject = CreateObject("Object");

			if (WMGRI.PerkUpgradesList[perkIdx].PerkUpgrade.default.bShouldLocalize)
				S = WMGRI.PerkUpgradesList[perkIdx].PerkUpgrade.static.GetUpgradeName();
			else
				S = WMGRI.PerkUpgradesList[perkIdx].PerkUpgrade.default.UpgradeName;

			ItemObject.SetString("label", default.DeluxeRandomPrefix @S);
			ItemObject.SetString("description", default.DeluxeRandomDescription);

			S = "img://"$PathName(WMGRI.PerkUpgradesList[perkIdx].PerkUpgrade.static.GetUpgradeIcon(0));
			ItemObject.SetString("iconURLSmall", S);
			ItemObject.SetString("iconURLLarge", S);

			FillDeluxeRowCommon(ItemObject, x, TempPrice);

			RowInfo.bRandom = True;
			RowInfo.TargetIndex = perkIdx;
			DeluxeRows.AddItem(RowInfo);

			ItemArray.SetElementObject(x, ItemObject);
			++x;
		}
	}
}

// Shared GFx field setup for a Deluxe action row. type 0 = affordable
// (highlighted), type 1 = greyed; active stays False (it is an action, not an
// equipped/owned state).
function FillDeluxeRowCommon(GFxObject ItemObject, int DefIndex, int Cost)
{
	ItemObject.SetInt("count", Cost);
	ItemObject.SetString("price", "");
	ItemObject.Setstring("typeRarity", "");
	ItemObject.SetBool("exchangeable", False);
	ItemObject.SetBool("recyclable", False);
	ItemObject.SetInt("definition", DefIndex);
	ItemObject.SetBool("active", False);
	if (WMPRI.Score < Cost)
		ItemObject.SetInt("type", 1);
	else
		ItemObject.SetInt("type", 0);
}

// True if the given perk has at least one owned, non-Deluxe skill (matches the
// random-path eligibility the server enforces).
function bool PerkHasEligibleDeluxeSkill(DKGameReplicationInfo DKGRI, int PerkIdx)
{
	local int i;
	local string PerkPath;

	PerkPath = PathName(DKGRI.PerkUpgradesList[PerkIdx].PerkUpgrade);
	for (i = 0; i < DKGRI.SkillUpgradesList.Length; ++i)
	{
		if (DKGRI.SkillUpgradesList[i].PerkPathName ~= PerkPath && WMPRI.GetSkillUpgrade(i) == 1)
			return True;
	}
	return False;
}

// ===================================================================
// Weapon Upgrade list builder - parent body verbatim + Hollow skill gate.
// ===================================================================
function BuildWeaponUpgradeList(out GFxObject ItemArray)
{
	local bool bPurchased;
	local GFxObject ItemObject;
	local int i, x, lvl, MaxLevel, TempPrice;
	local string S;

	WeaponUPGIndex.Length = 0;
	x = 0;

	for (i = 0; i < WMGRI.WeaponUpgradeSlotsList.Length; ++i)
	{
		if (IsWeaponInInventory(WMGRI.WeaponUpgradeSlotsList[i].KFWeapon))
		{
			// DK: Hollow skill gate - Hollow weapon-upgrade slots are present
			// server-wide for random-seed parity, but must stay hidden until this
			// player has purchased the linked skill (and Deluxe tier when required).
			if (ClassIsChildOf(WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade, class'DKWeaponUpg_HollowBase')
				&& !PlayerOwnsRequiredHollowSkill(class<DKWeaponUpg_HollowBase>(WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade)))
				continue;

			lvl = WMPRI.GetWeaponUpgrade(i);

			MaxLevel = WMGRI.WeaponUpgradeSlotsList[i].MaxLevel;

			// Is it fully bought?
			if (lvl >= MaxLevel)
				bPurchased = True;
			else
				bPurchased = False;

			// Create info arch
			if ((CurrentUpgradeFilter == EWMInv_All) || (CurrentUpgradeFilter == EWMInv_Available && !bPurchased) || (CurrentUpgradeFilter == EWMInv_Purchased && bPurchased))
			{
				if (bPurchased)
					--lvl;

				ItemObject = CreateObject("Object");
				TempPrice = WMGRI.WeaponUpgradeSlotsList[i].BasePrice * (lvl + 1);
				ItemObject.SetInt("count", TempPrice);

				if (WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade.default.bShouldLocalize)
					S = WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade.static.GetUpgradeName();
				else
					S = WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade.default.UpgradeName;

				if (MaxLevel > 1)
				{
					if (bPurchased)
						S @= "(" $MaxLevel $"/" $MaxLevel $")";
					else
						S @= "(" $lvl $"/" $MaxLevel $")";
				}

				ItemObject.SetString("label", S);
				ItemObject.SetString("price", "");
				ItemObject.Setstring("typeRarity", "");
				ItemObject.SetBool("exchangeable", False);
				ItemObject.SetBool("recyclable", False);
				ItemObject.SetInt("definition", x);
				if (bPurchased)
				{
					ItemObject.SetInt("type", 1);
					ItemObject.SetBool("active", True);
					ItemObject.SetInt("rarity", 0);
				}
				else
				{
					if (WMPRI.Score < TempPrice)
						ItemObject.SetInt("type", 1);
					else
						ItemObject.SetInt("type", 0);

					ItemObject.SetBool("active", False);
				}

				if (WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade.default.bShouldLocalize)
					S = repl(WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade.static.GetUpgradeDescription(), "%x%", WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade.static.GetBonusValue(lvl + 1));
				else
					S = repl(WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade.default.UpgradeDescription[0], "%x%", WMGRI.WeaponUpgradeSlotsList[i].WeaponUpgrade.static.GetBonusValue(lvl + 1));
				ItemObject.SetString("description", S);
				S = "img://"$PathName(WMGRI.WeaponUpgradeSlotsList[i].KFWeapon.default.WeaponSelectTexture);
				ItemObject.SetString("iconURLSmall", S);
				ItemObject.SetString("iconURLLarge", S);
				ItemArray.SetElementObject(x, ItemObject);
				WeaponUPGIndex.AddItem(i);
				++x;
			}
		}
	}
}

// ===================================================================
// Hollow skill gate - Hollow weapon-upgrade slots exist server-wide in
// WeaponUpgradeSlotsList for seed parity, but must only be VISIBLE to a
// player who has purchased the linked skill (and its Deluxe tier when the
// upgrade requires it). This is the display filter the base class documents.
// ===================================================================
function bool PlayerOwnsRequiredHollowSkill(class<DKWeaponUpg_HollowBase> HollowUpg)
{
	local int s;
	local string ReqPath;

	ReqPath = HollowUpg.default.RequiredSkillClassPath;

	// No requirement declared -> always visible (base default is "").
	if (ReqPath == "")
		return True;

	for (s = 0; s < WMGRI.SkillUpgradesList.Length; ++s)
	{
		if (PathName(WMGRI.SkillUpgradesList[s].SkillUpgrade) ~= ReqPath)
		{
			// Skill must be purchased at least once.
			if (WMPRI.GetSkillUpgrade(s) <= 0)
				return False;

			// Deluxe-only upgrades additionally require the Deluxe tier.
			if (HollowUpg.default.bRequiresDeluxe && !WMPRI.IsSkillDeluxe(s))
				return False;

			return True;
		}
	}

	// Linked skill is not in this game's skill list -> hide it.
	return False;
}

// ===================================================================
// EQUIP CALLBACK - parent body with two changes:
//  (1) PAGED: perk-tab read/write use GetPerkLevel/SetPerkLevel.
//  (2) Skill tab: definitions past SkillUPGIndex.Length are Deluxe action
//      rows; dispatch them to the server RPCs. All other tabs are verbatim.
// ===================================================================
function Callback_Equip(int ItemDefinition)
{
	local int Index, lvl, UPGPrice, OriginalDosh;
	local DKPlayerReplicationInfo DKPRI;
	local DKGameReplicationInfo DKGRI;
	local DKPlayerController DKPC;
	local int d;

	if (ItemDefinition == -1)
		return;

	if (!WMPRI.SyncCompleted)
	{
		if (!WMPRI.SyncTimerActive())
			WMPRI.SetSyncTimer(self, ItemDefinition);

		return;
	}

	DKPRI = DKPlayerReplicationInfo(WMPRI);
	DKGRI = DKGameReplicationInfo(WMGRI);

	Index = ItemDefinition;

	//Upgrades
	if (CurrentFilterIndex == 0) //Perk Upgrades (DK paged)
	{
		Index = PerkUPGIndex[Index];
		lvl = DKPRI.GetPerkLevel(Index);
		UPGPrice = WMGRI.PerkUpgPrice[lvl];

		if (WMPRI.Score >= UPGPrice)
		{
			OriginalDosh = WMPRI.Score;
			if (WMPC.WorldInfo.NetMode != NM_Standalone)
				WMPRI.SyncCompleted = False;
			WMPC.BuyPerkUpgrade(Index, UPGPrice);
			if (WMPC.WorldInfo.NetMode != NM_Standalone)
				DKPRI.SetPerkLevel(Index, lvl + 1);
			WMPRI.Score = OriginalDosh - UPGPrice;
			if (WMPRI.Purchase_PerkUpgrade.Find(Index) == INDEX_NONE)
				WMPRI.Purchase_PerkUpgrade.AddItem(Index);
			UnlockRandomSkill(PathName(WMGRI.PerkUpgradesList[Index].PerkUpgrade), WMGRI.bDeluxeSkillUnlock[lvl] == 1);
			Owner.PlaySoundBase(default.PerkSound, True);
		}
	}
	else if (CurrentFilterIndex == 1) //Skill Upgrades (+ DK Deluxe rows)
	{
		// Deluxe action rows are appended past the normal skill rows.
		if (Index >= SkillUPGIndex.Length)
		{
			d = Index - SkillUPGIndex.Length;
			DKPC = DKPlayerController(WMPC);
			if (DKGRI != None && DKPC != None && DKGRI.bDeluxeUpgradeEnabled
				&& d >= 0 && d < DeluxeRows.Length
				&& WMPRI.Score >= DKGRI.DeluxeUpgradeCost)
			{
				OriginalDosh = WMPRI.Score;

				if (DeluxeRows[d].bRandom)
				{
					DKPC.ServerBuyDeluxeUpgradeRandom(DeluxeRows[d].TargetIndex);
					// We cannot predict which skill the server rolls, so we do
					// not flip a specific skill here; the authoritative state
					// replicates back and the row is rebuilt against it (it
					// stays only while the perk still has an eligible owned,
					// non-Deluxe skill).
				}
				else
				{
					DKPC.ServerBuyDeluxeUpgrade(DeluxeRows[d].TargetIndex);
					// Mirror the server's flip locally (UnlockSkillUpgrade is
					// simulated) so this skill reads as Deluxe immediately and
					// the row drops out of the list on the Refresh below, instead
					// of lingering as a free re-buy until replication catches up.
					if (WMPC.WorldInfo.NetMode != NM_Standalone)
						WMPRI.UnlockSkillUpgrade(DeluxeRows[d].TargetIndex, True);
				}

				// Optimistic dosh deduction for immediate feedback; the server
				// charges authoritatively and the replicated Score reconciles.
				if (WMPC.WorldInfo.NetMode != NM_Standalone)
					WMPRI.Score = OriginalDosh - DKGRI.DeluxeUpgradeCost;

				Owner.PlaySoundBase(default.SkillSound, True);
			}
		}
		else
		{
			Index = SkillUPGIndex[Index];

			if (WMPRI.IsSkillDeluxe(Index))
				UPGPrice = WMGRI.SkillUpgDeluxePrice;
			else
				UPGPrice = WMGRI.SkillUpgPrice;

			if (WMPRI.Score >= UPGPrice)
			{
				OriginalDosh = WMPRI.Score;
				if (WMPC.WorldInfo.NetMode != NM_Standalone)
					WMPRI.SyncCompleted = False;
				WMPC.BuySkillUpgrade(Index, GetPerkRelatedIndex(Index), UPGPrice);
				if (WMPC.WorldInfo.NetMode != NM_Standalone)
					WMPRI.PurchaseSkillUpgrade(Index);
				WMPRI.Score = OriginalDosh - UPGPrice;
				if (WMPRI.Purchase_SkillUpgrade.Find(Index) == INDEX_NONE)
					WMPRI.Purchase_SkillUpgrade.AddItem(Index);
				Owner.PlaySoundBase(default.SkillSound, True);
			}
		}
	}
	else if (CurrentFilterIndex == 2) //Weapon Upgrades
	{
		Index = WeaponUPGIndex[Index];
		lvl = WMPRI.GetWeaponUpgrade(Index);
		UPGPrice = WMGRI.WeaponUpgradeSlotsList[Index].BasePrice * (lvl + 1);

		if (WMPRI.Score >= UPGPrice)
		{
			OriginalDosh = WMPRI.Score;
			if (WMPC.WorldInfo.NetMode != NM_Standalone)
				WMPRI.SyncCompleted = False;
			WMPC.BuyWeaponUpgrade(Index, UPGPrice);
			if (WMPC.WorldInfo.NetMode != NM_Standalone)
				WMPRI.SetWeaponUpgrade(Index, lvl + 1);
			WMPRI.Score = OriginalDosh - UPGPrice;
			WMPC.UpdateWeaponMagAndCap();
			if (WMPRI.Purchase_WeaponUpgrade.Find(Index) == INDEX_NONE)
				WMPRI.Purchase_WeaponUpgrade.AddItem(Index);
			Owner.PlaySoundBase(default.WeaponSound, True);
		}
	}
	else if (CurrentFilterIndex == 3) //Equipment Upgrades
	{
		Index = EquipmentUPGIndex[Index];
		lvl = WMPRI.bEquipmentUpgrade[Index];
		if (WMGRI.EquipmentUpgradesList[Index].MaxLevel > 1)
			UPGPrice = WMGRI.EquipmentUpgradesList[Index].BasePrice +
			Round(float(WMGRI.EquipmentUpgradesList[Index].MaxPrice - WMGRI.EquipmentUpgradesList[Index].BasePrice) / float(WMGRI.EquipmentUpgradesList[Index].MaxLevel - 1) * lvl);
		else
			UPGPrice = WMGRI.EquipmentUpgradesList[Index].BasePrice;

		if (WMPRI.Score >= UPGPrice)
		{
			OriginalDosh = WMPRI.Score;
			if (WMPC.WorldInfo.NetMode != NM_Standalone)
				WMPRI.SyncCompleted = False;
			WMPC.BuyEquipmentUpgrade(Index, UPGPrice);
			if (WMPC.WorldInfo.NetMode != NM_Standalone)
				WMPRI.bEquipmentUpgrade[Index] = lvl + 1;
			WMPRI.Score = OriginalDosh - UPGPrice;
			WMPC.UpdateWeaponMagAndCap();
			if (WMPRI.Purchase_EquipmentUpgrade.Find(Index) == INDEX_NONE)
				WMPRI.Purchase_EquipmentUpgrade.AddItem(Index);
			Owner.PlaySoundBase(default.EquipmentSound, True);
		}
	}
	else if (CurrentFilterIndex == 4) //Sidearms
	{
		UPGPrice = WMGRI.SidearmsList[Index].BuyPrice;
		if (WMPRI.bSidearmItem[Index] == 0 && UPGPrice > 0)
		{
			if (WMPRI.Score >= UPGPrice)
			{
				OriginalDosh = WMPRI.Score;
				if (WMPC.WorldInfo.NetMode != NM_Standalone)
					WMPRI.SyncCompleted = False;
				WMPC.BuySidearm(Index, UPGPrice);
				if (WMPC.WorldInfo.NetMode != NM_Standalone)
					WMPRI.bSidearmItem[Index] = 1;
				WMPRI.Score = OriginalDosh - UPGPrice;
				WMPC.ChangeSidearm(Index);
			}
		}
		else
			WMPC.ChangeSidearm(Index);
	}
	else if (CurrentFilterIndex == 5) //Grenades
	{
		WMPC.ChangeGrenade(Index);
	}
	else if (CurrentFilterIndex == 6) //Knives
	{
		WMPC.ChangeKnife(Index);
	}

	Refresh();
}

// ===================================================================
// ITEM DETAILS CLICK - parent body with PAGED perk price and Deluxe-row
// price label; all other tabs verbatim.
// ===================================================================
function CallBack_ItemDetailsClicked(int ItemDefinition)
{
	local int Index, lvl, price;
	local DKPlayerReplicationInfo DKPRI;
	local DKGameReplicationInfo DKGRI;

	if (!WMPRI.SyncCompleted && WMPRI.SyncTimerActive())
	{
		EquipButton.SetString("label", "...");
		return;
	}

	DKPRI = DKPlayerReplicationInfo(WMPRI);
	DKGRI = DKGameReplicationInfo(WMGRI);

	Index = ItemDefinition;
	Owner.PlaySoundBase(default.SelectSound, True);

	//Upgrades
	if (CurrentFilterIndex == 0) //Perk Upgrades (DK paged)
	{
		Index = PerkUPGIndex[Index];
		lvl = DKPRI.GetPerkLevel(Index);
		price = WMGRI.PerkUpgPrice[lvl];

		EquipButton.SetString("label", ""$price$Chr(163));
	}
	else if (CurrentFilterIndex == 1) //Skill Upgrades (+ DK Deluxe rows)
	{
		if (Index >= SkillUPGIndex.Length)
		{
			// Deluxe action row.
			if (DKGRI != None)
				EquipButton.SetString("label", ""$DKGRI.DeluxeUpgradeCost$Chr(163));
			else
				EquipButton.SetString("label", default.EquipButtonString);
		}
		else
		{
			Index = SkillUPGIndex[Index];

			if (WMPRI.IsSkillDeluxe(Index))
				price = WMGRI.SkillUpgDeluxePrice;
			else
				price = WMGRI.SkillUpgPrice;
			EquipButton.SetString("label", ""$price$Chr(163));
		}
	}
	else if (CurrentFilterIndex == 2) //Weapon Upgrades
	{
		Index = WeaponUPGIndex[Index];
		lvl = WMPRI.GetWeaponUpgrade(Index);
		EquipButton.SetString("label", ""$WMGRI.WeaponUpgradeSlotsList[Index].BasePrice * (lvl + 1)$Chr(163));
	}
	else if (CurrentFilterIndex == 3) //Equipment Upgrades
	{
		Index = EquipmentUPGIndex[Index];
		lvl = WMPRI.bEquipmentUpgrade[Index];
		if (WMGRI.EquipmentUpgradesList[Index].MaxLevel > 1)
			EquipButton.SetString("label", ""$WMGRI.EquipmentUpgradesList[Index].BasePrice +
				Round(float(WMGRI.EquipmentUpgradesList[Index].MaxPrice - WMGRI.EquipmentUpgradesList[Index].BasePrice) /
				float(WMGRI.EquipmentUpgradesList[Index].MaxLevel - 1) * lvl)$Chr(163));
		else
			EquipButton.SetString("label", ""$WMGRI.EquipmentUpgradesList[Index].BasePrice$Chr(163));
	}
	else if (CurrentFilterIndex == 4) //Sidearms
	{
		if (WMPRI.bSidearmItem[Index] == 0 && WMGRI.SidearmsList[Index].BuyPrice > 0)
			EquipButton.SetString("label", ""$WMGRI.SidearmsList[Index].BuyPrice$Chr(163));
		else
			EquipButton.SetString("label", default.EquipButtonString);
	}
	else if (CurrentFilterIndex == 5 || CurrentFilterIndex == 6) //Knives and Grenades
	{
		EquipButton.SetString("label", default.EquipButtonString);
	}
}

// ===================================================================
// SKILL REROLL UNLOCK - parent body verbatim with PAGED level read
// (GetPerkLevel replaces WMPRI.bPerkUpgrade[PerkIndex].level).
// ===================================================================
function SkillRerollUnlock(int PerkIndex)
{
	local string RerollPerkPathName;
	local int i;
	local DKPlayerReplicationInfo DKPRI;

	DKPRI = DKPlayerReplicationInfo(WMPRI);

	if (WMPRI.RerollSyncCompleted)
	{
		RerollPerkPathName = PathName(WMGRI.PerkUpgradesList[PerkIndex].PerkUpgrade);

		for (i = 0; i < DKPRI.GetPerkLevel(PerkIndex); ++i)
		{
			UnlockRandomSkill(RerollPerkPathName, WMGRI.bDeluxeSkillUnlock[i] == 1);
		}

		Refresh();
		ResetRerollVars();
	}
	else
		WMPRI.SetRerollSyncTimer(self, PerkIndex);
}

defaultproperties
{
	DeluxeTargetedSuffix="- Upgrade to Deluxe"
	DeluxeRandomPrefix="Deluxe (Random):"
	DeluxeRandomDescription="Spend dosh to upgrade a random owned skill of this perk to its Deluxe version."
}
