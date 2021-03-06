-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local _, TSM = ...
local MoveContext = TSM.Banking:NewPackage("MoveContext")
local private = {
	bagToBank = nil,
	bankToBag = nil,
	bagToGuildBank = nil,
	guildBankToBag = nil,
}
-- don't use MAX_GUILDBANK_SLOTS_PER_TAB since it isn't available right away
local GUILD_BANK_TAB_SLOTS = 98



-- ============================================================================
-- BaseMoveContext Class
-- ============================================================================

local BaseMoveContext = TSM.Include("LibTSMClass").DefineClass("BaseMoveContext", nil, "ABSTRACT")



-- ============================================================================
-- BagToBankMoveContext Class
-- ============================================================================

local BagToBankMoveContext = TSM.Include("LibTSMClass").DefineClass("BagToBankMoveContext", BaseMoveContext)

function BagToBankMoveContext.MoveSlot(self, fromSlotId, toSlotId, quantity)
	local fromBag, fromSlot = TSM.SlotId.Split(fromSlotId)
	SplitContainerItem(fromBag, fromSlot, quantity)
	if GetCursorInfo() == "item" then
		PickupContainerItem(TSM.SlotId.Split(toSlotId))
	end
	ClearCursor()
end

function BagToBankMoveContext.GetSlotQuantity(self, slotId)
	return private.BagBankGetSlotQuantity(slotId)
end

function BagToBankMoveContext.SlotIdIterator(self, itemString)
	return private.BagSlotIdIterator(itemString)
end

function BagToBankMoveContext.GetEmptySlotsThreaded(self, emptySlotIds)
	local sortValue = TSMAPI_FOUR.Thread.AcquireSafeTempTable()
	if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
		private.GetEmptySlotsHelper(REAGENTBANK_CONTAINER, emptySlotIds, sortValue)
	end
	private.GetEmptySlotsHelper(BANK_CONTAINER, emptySlotIds, sortValue)
	for bag = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		private.GetEmptySlotsHelper(bag, emptySlotIds, sortValue)
	end
	TSM.Table.SortWithValueLookup(emptySlotIds, sortValue)
	TSMAPI_FOUR.Thread.ReleaseSafeTempTable(sortValue)
end

function BagToBankMoveContext.GetTargetSlotId(self, itemString, emptySlotIds)
	return private.BagBankGetTargetSlotId(itemString, emptySlotIds)
end



-- ============================================================================
-- BankToBagMoveContext Class
-- ============================================================================

local BankToBagMoveContext = TSM.Include("LibTSMClass").DefineClass("BankToBagMoveContext", BaseMoveContext)

function BankToBagMoveContext.MoveSlot(self, fromSlotId, toSlotId, quantity)
	local fromBag, fromSlot = TSM.SlotId.Split(fromSlotId)
	SplitContainerItem(fromBag, fromSlot, quantity)
	if GetCursorInfo() == "item" then
		PickupContainerItem(TSM.SlotId.Split(toSlotId))
	end
	ClearCursor()
end

function BankToBagMoveContext.GetSlotQuantity(self, slotId)
	return private.BagBankGetSlotQuantity(slotId)
end

function BankToBagMoveContext.SlotIdIterator(self, itemString)
	local query = TSM.Inventory.BagTracking.CreateQuery()
		:Select("slotId", "quantity")
		:Or()
			:Equal("bag", BANK_CONTAINER)
			:And()
				:GreaterThan("bag", NUM_BAG_SLOTS)
				:LessThanOrEqual("bag", NUM_BAG_SLOTS + NUM_BANKBAGSLOTS)
			:End()
	if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and IsReagentBankUnlocked() then
		query:Equal("bag", REAGENTBANK_CONTAINER)
	end
	query:End() -- end the Or()
		:Equal("autoBaseItemString", TSMAPI_FOUR.Item.ToBaseItemString(itemString, true))

	return query:IteratorAndRelease()
end

function BankToBagMoveContext.GetEmptySlotsThreaded(self, emptySlotIds)
	private.BagGetEmptySlotsThreaded(emptySlotIds)
end

function BankToBagMoveContext.GetTargetSlotId(self, itemString, emptySlotIds)
	return private.BagBankGetTargetSlotId(itemString, emptySlotIds)
end



-- ============================================================================
-- BagToGuildBankMoveContext Class
-- ============================================================================

local BagToGuildBankMoveContext = TSM.Include("LibTSMClass").DefineClass("BagToGuildBankMoveContext", BaseMoveContext)

function BagToGuildBankMoveContext.MoveSlot(self, fromSlotId, toSlotId, quantity)
	local fromBag, fromSlot = TSM.SlotId.Split(fromSlotId)
	SplitContainerItem(fromBag, fromSlot, quantity)
	if GetCursorInfo() == "item" then
		PickupGuildBankItem(TSM.SlotId.Split(toSlotId))
	end
	ClearCursor()
end

function BagToGuildBankMoveContext.GetSlotQuantity(self, slotId)
	return private.BagBankGetSlotQuantity(slotId)
end

function BagToGuildBankMoveContext.SlotIdIterator(self, itemString)
	return private.BagSlotIdIterator(itemString)
end

function BagToGuildBankMoveContext.GetEmptySlotsThreaded(self, emptySlotIds)
	local currentTab = GetCurrentGuildBankTab()
	local _, _, _, _, numWithdrawals = GetGuildBankTabInfo(currentTab)
	if numWithdrawals == -1 or numWithdrawals >= GUILD_BANK_TAB_SLOTS then
		for slot = 1, GUILD_BANK_TAB_SLOTS do
			if not GetGuildBankItemInfo(currentTab, slot) then
				tinsert(emptySlotIds, TSM.SlotId.Join(currentTab, slot))
			end
		end
	end
	for tab = 1, GetNumGuildBankTabs() do
		if tab ~= currentTab then
			-- only use tabs which we have at least enough withdrawals to withdraw every slot
			_, _, _, _, numWithdrawals = GetGuildBankTabInfo(tab)
			if numWithdrawals == -1 or numWithdrawals >= GUILD_BANK_TAB_SLOTS then
				for slot = 1, GUILD_BANK_TAB_SLOTS do
					if not GetGuildBankItemInfo(tab, slot) then
						tinsert(emptySlotIds, TSM.SlotId.Join(tab, slot))
					end
				end
			end
		end
	end
end

function BagToGuildBankMoveContext.GetTargetSlotId(self, itemString, emptySlotIds)
	return tremove(emptySlotIds, 1)
end



-- ============================================================================
-- GuildBankToBagMoveContext Class
-- ============================================================================

local GuildBankToBagMoveContext = TSM.Include("LibTSMClass").DefineClass("GuildBankToBagMoveContext", BaseMoveContext)

function GuildBankToBagMoveContext.MoveSlot(self, fromSlotId, toSlotId, quantity)
	local fromTab, fromSlot = TSM.SlotId.Split(fromSlotId)
	SplitGuildBankItem(fromTab, fromSlot, quantity)
	if GetCursorInfo() == "item" then
		PickupContainerItem(TSM.SlotId.Split(toSlotId))
	end
	ClearCursor()
end

function GuildBankToBagMoveContext.GetSlotQuantity(self, slotId)
	local tab, slot = TSM.SlotId.Split(slotId)
	QueryGuildBankTab(tab)
	local _, quantity = GetGuildBankItemInfo(tab, slot)
	return quantity or 0
end

function GuildBankToBagMoveContext.SlotIdIterator(self, itemString)
	return TSM.Inventory.GuildTracking.CreateQuery()
		:Select("slotId", "quantity")
		:Equal("autoBaseItemString", TSMAPI_FOUR.Item.ToBaseItemString(itemString, true))
		:IteratorAndRelease()
end

function GuildBankToBagMoveContext.GetEmptySlotsThreaded(self, emptySlotIds)
	private.BagGetEmptySlotsThreaded(emptySlotIds)
end

function GuildBankToBagMoveContext.GetTargetSlotId(self, itemString, emptySlotIds)
	return private.BagBankGetTargetSlotId(itemString, emptySlotIds)
end



-- ============================================================================
-- Module Functions
-- ============================================================================

function MoveContext.GetBagToBank()
	private.bagToBank = private.bagToBank or BagToBankMoveContext()
	return private.bagToBank
end

function MoveContext.GetBankToBag()
	private.bankToBag = private.bankToBag or BankToBagMoveContext()
	return private.bankToBag
end

function MoveContext.GetBagToGuildBank()
	private.bagToGuildBank = private.bagToGuildBank or BagToGuildBankMoveContext()
	return private.bagToGuildBank
end

function MoveContext.GetGuildBankToBag()
	private.guildBankToBag = private.guildBankToBag or GuildBankToBagMoveContext()
	return private.guildBankToBag
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.BagBankGetSlotQuantity(slotId)
	local _, quantity = GetContainerItemInfo(TSM.SlotId.Split(slotId))
	return quantity or 0
end

function private.BagSlotIdIterator(itemString)
	local query = TSM.Inventory.BagTracking.CreateQuery()
		:Select("slotId", "quantity")
		:GreaterThanOrEqual("bag", BACKPACK_CONTAINER)
		:LessThanOrEqual("bag", NUM_BAG_SLOTS)
		:Equal("autoBaseItemString", TSMAPI_FOUR.Item.ToBaseItemString(itemString, true))
	if TSM.Banking.IsGuildBankOpen() then
		query:Equal("isBoA", false)
		query:Equal("isBoP", false)
	end
	return query:IteratorAndRelease()
end

function private.BagGetEmptySlotsThreaded(emptySlotIds)
	local sortValue = TSMAPI_FOUR.Thread.AcquireSafeTempTable()
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		private.GetEmptySlotsHelper(bag, emptySlotIds, sortValue)
	end
	TSM.Table.SortWithValueLookup(emptySlotIds, sortValue)
	TSMAPI_FOUR.Thread.ReleaseSafeTempTable(sortValue)
end

function private.GetEmptySlotsHelper(bag, emptySlotIds, sortValue)
	local isSpecial = nil
	if bag == REAGENTBANK_CONTAINER then
		isSpecial = true
	elseif bag == BACKPACK_CONTAINER or bag == BANK_CONTAINER then
		isSpecial = false
	else
		isSpecial = (GetItemFamily(GetInventoryItemLink("player", ContainerIDToInventoryID(bag))) or 0) ~= 0
	end
	for slot = 1, GetContainerNumSlots(bag) do
		if not GetContainerItemInfo(bag, slot) then
			local slotId = TSM.SlotId.Join(bag, slot)
			tinsert(emptySlotIds, slotId)
			sortValue[slotId] = slotId + (isSpecial and 0 or 100000)
		end
	end
end

function private.BagBankGetTargetSlotId(itemString, emptySlotIds)
	for i, slotId in ipairs(emptySlotIds) do
		local bag = TSM.SlotId.Split(slotId)
		if TSMAPI_FOUR.Inventory.ItemWillGoInBag(TSMAPI_FOUR.Item.GetLink(itemString), bag) then
			return tremove(emptySlotIds, i)
		end
	end
end
