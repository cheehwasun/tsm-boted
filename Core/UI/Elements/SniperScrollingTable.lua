-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

--- SniperScrollingTable UI Element Class.
-- A special auction scrolling table used for sniper which has an extra icon column on the left. It is a subclass of the
-- @{AuctionScrollingTable} class.
-- @classmod SniperScrollingTable

-- ahbot
print("reuqire")
print("reuqire")
print("reuqire")

local _, TSM = ...
local SniperScrollingTable = TSM.Lib.Class.DefineClass("SniperScrollingTable", TSM.UI.ShoppingScrollingTable)
TSM.UI.SniperScrollingTable = SniperScrollingTable
local private = { rowFrameLookup = {} }



-- ============================================================================
-- Public Class Methods
-- ============================================================================

function SniperScrollingTable.__init(self)
	self.__super:__init()

	self._highestFilterId = 0
	self._onRowRemovedHandler = nil
end

function SniperScrollingTable.Acquire(self)
	self._highestFilterId = 0
	self.__super:Acquire()
	self:GetScrollingTableInfo()
		:NewColumn("icon", true)
			:SetTitles("")
			:SetWidth(14)
			:SetJustifyH("CENTER")
			:SetFont(TSM.UI.Fonts.MontserratRegular)
			:SetFontHeight(12)
			:SetSortValueFunction(private.IconSortFunction)
			:Commit()
		:RemoveColumn("timeLeft")
		:SetDefaultSort("icon", true)
		:Commit()
end

function SniperScrollingTable.Release(self)
	self._onRowRemovedHandler = nil
	for _, row in ipairs(self._rows) do
		private.rowFrameLookup[row._frame] = nil
	end
	self.__super:Release()
end

--- Registers a script handler.
-- @tparam SniperScrollingTable self The sniper scrolling table object
-- @tparam string script The script to register for (supported scripts: `OnRowRemoved`)
-- @tparam function handler The script handler which will be called with the sniper scrolling table object followed by
-- any arguments to the script
-- @treturn SniperScrollingTable The sniper scrolling table object
function SniperScrollingTable.SetScript(self, script, handler)
	if script == "OnRowRemoved" then
		self._onRowRemovedHandler = handler
	else
		self.__super:SetScript(script, handler)
	end
	return self
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

function SniperScrollingTable._UpdateData(self, queryChanged)
	self.__super:_UpdateData(queryChanged)
	self._highestFilterId = 0
	for _, record in pairs(self._baseRecordByHash) do
		self._highestFilterId = max(self._highestFilterId, record:GetField("filterId"))
	end
end

function SniperScrollingTable._GetTableRow(self, isHeader)
	local row = self.__super:_GetTableRow(isHeader)
	if not isHeader then
		private.rowFrameLookup[row._frame] = row

		-- add the remove button before the first col
		local remove = row:_GetTexture()
		TSM.UI.TexturePacks.SetTextureAndSize(remove, "iconPack.14x14/Close/Default")
		remove:SetPoint("CENTER", row._texts.icon, 0, 0)
		row._icons.remove = remove

		local removeBtn = row:_GetButton()
		removeBtn:SetAllPoints(remove)
		removeBtn:SetScript("OnEnter", private.RemoveRowBtnOnEnter)
		removeBtn:SetScript("OnLeave", private.RemoveRowBtnOnLeave)
		removeBtn:SetScript("OnClick", private.RemoveRowBtnOnClick)
		row._buttons.remove = removeBtn
	end
	return row
end

-- ahbot
local function dump (  value , call_indent)
	if not call_indent then 
		call_indent = ""
	end

	local indent = call_indent .. "  "

	local output = ""

	if type(value) == "table" then
		output = output .. "{"
		local first = true
		for inner_key, inner_value in pairs ( value ) do
			if not first then 
			output = output .. ", "
			else
			first = false
			end
			output = output .. "\n" .. indent
			output = output  .. inner_key .. " = " .. dump ( inner_value, indent ) 
		end
		output = output ..  "\n" .. call_indent .. "}"

	elseif type (value) == "userdata" then
		output = "userdata"
	else 
		output =  value
	end
	return output 
end
-- ahbot

function SniperScrollingTable._SetRowData(self, row, data)
	-- print("trace step SniperScrollingTable._SetRowData")
	-- print(type(row))

	-- for key,value in pairs(row) do 
	-- 	print(key,value)
	-- end

	local record = self._baseRecordByHash[data]
	local isRecent = self._highestFilterId == record:GetField("filterId")
	print("ahbot trace");
	print("record", type(record), record)
	pprint(record)
	print("row",  type(row), row)
	
	print("data",  type(data), data)
	error("ahbot err")
	TSM.UI.TexturePacks.SetTexture(row._icons.remove, isRecent and "iconPack.14x14/New" or "iconPack.14x14/Close/Default")
	self.__super:_SetRowData(row, data)
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.IconSortFunction(_, record)
	return -record:GetField("filterId")
end



-- ============================================================================
-- Local Script Handlers
-- ============================================================================

function private.RemoveRowBtnOnEnter(button)
	local self = private.rowFrameLookup[button:GetParent()]
	TSM.UI.TexturePacks.SetTexture(self._icons.remove, "iconPack.14x14/Close/Default")
end

function private.RemoveRowBtnOnLeave(button)
	local self = private.rowFrameLookup[button:GetParent()]
	local scrollingTable = self._scrollingTable
	local record = scrollingTable._baseRecordByHash[self:GetData()]
	if not record then
		-- this row was just removed
		return
	end
	local isRecent = scrollingTable._highestFilterId == record:GetField("filterId")
	TSM.UI.TexturePacks.SetTexture(self._icons.remove, isRecent and "iconPack.14x14/New" or "iconPack.14x14/Close/Default")
end

function private.RemoveRowBtnOnClick(button)
	local self = private.rowFrameLookup[button:GetParent()]
	local scrollingTable = self._scrollingTable
	if scrollingTable._onRowRemovedHandler then
		scrollingTable:_onRowRemovedHandler(scrollingTable._baseRecordByHash[self:GetData()])
	end
end
