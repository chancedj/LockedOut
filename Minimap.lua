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
	OnClick = function() addon:OnClick() end,
	OnEnter = function() addon:OnEnter() end,
	OnLeave = function() addon:OnLeave() end,
}); -- local LockHelperMo

function addon:OnInitialize()
	LockHelperMapDb = LockHelperMapDb or LibStub("AceDB-3.0"):New("LockHelperMapDb", { profile = { minimap = {hide = false } } });

	icon:Register(addonName, LockHelperMo, LockHelperMapDb.profile.minimap)
end -- addon:OnInitialize

function addon:OnClick()
	LockHelper_PrintMsg();
end -- addon:OnClick

function addon:OnEnter()
	print("you entered ..." .. addonName);
end --  addon:OnEnter

function addon:OnLeave()
	print("you left ..." .. addonName);
end -- addon:OnLeave