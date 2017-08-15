--[[
	This file is for dealing with handling the minimap creation and display
--]]
local addonName, ns = ...;

local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");
local icon = LibStub("LibDBIcon-1.0");
local LockHelperMo = LibStub("LibDataBroker-1.1"):NewDataObject("Lock Helper", {
	type = "data source",
	text = "Lock Helper",
	icon = "Interface\\Icons\\Inv_misc_key_10",
	OnClick = function( self ) addon:OnClick( self ) end,
	OnEnter = function( self ) addon:OnEnter( self ) end,
	OnLeave = function( self ) addon:OnLeave( self ) end,
}); -- local LockHelperMo

function addon:OnInitialize()
	LockHelperMapDb = LockHelperMapDb or LibStub("AceDB-3.0"):New("LockHelperMapDb", { profile = { minimap = {hide = false } } });

	icon:Register(addonName, LockHelperMo, LockHelperMapDb.profile.minimap)
end -- addon:OnInitialize

-- Get a reference to the lib
local LibQTip = LibStub('LibQTip-1.0')

function addon:OnClick()
	LockHelper_PrintMsg();
end -- addon:OnClick

function addon:OnEnter( self )
	-- Acquire a tooltip with 3 columns, respectively aligned to left, center and right
	local tooltip = LibQTip:Acquire("LockHelperTooltip", 3, "LEFT", "CENTER", "RIGHT");
	self.tooltip = tooltip;

	-- Add an header filling only the first two columns
	tooltip:AddHeader('Anchor', 'Tooltip');

	-- Add an new line, using all columns
	tooltip:AddLine('Hello', 'World', '!');

	-- Use smart anchoring code to anchor the tooltip to our frame
	tooltip:SmartAnchorTo(self);

	-- Show it, et voilà !
	tooltip:Show();
end --  addon:OnEnter

function addon:OnLeave( self )
   -- Release the tooltip
   LibQTip:Release( self.tooltip );
   self.tooltip = nil;
end -- addon:OnLeave
