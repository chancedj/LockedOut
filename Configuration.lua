--[[
	This file is to deal with the code to generate the lockout table/vector and
	to handle the refresh of data and deletion of stale data
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):NewAddon( addonName, "AceEvent-3.0" );
local L = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );
local icon = LibStub( "LibDBIcon-1.0" );

-- cache lua functions
local InterfaceOptionsFrame_OpenToCategory =	-- variables
	  InterfaceOptionsFrame_OpenToCategory		-- lua functions

local options = {
	type = "group",
	name = addonName,
	args = {
		enable = {
		  name = "Enable",
		  desc = "Enables / disables the addon",
		  type = "toggle",
		  set = function(info,val) print( info .. " = " .. val); end,
		  get = function(info) return print( info ); end
		},
		moreoptions={
		  name = "More Options",
		  type = "group",
		  args={
			enable = {
			  name = "Group Enable",
			  desc = "Testing args",
			  type = "toggle",
			}
		  }
		},
		evenmoreoptions={
		  name = "Even More Options",
		  type = "group",
		  args={
			enable = {
			  name = "Even more Group Enable",
			  desc = "Testing args",
			  type = "toggle",
			}
		  }
		}
	}
};

--addon.optionFrameName = addonName .. "OptionPanel";
--LibStub( "AceConfigRegistry-3.0" ):RegisterOptionsTable( addon.optionFrameName , options);
--addon.optionFrame = LibStub( "AceConfigDialog-3.0" ):AddToBlizOptions( addon.optionFrameName, addonName );
--addon.optionFrame.default = function() self:ResetDefaults() end;

function addon:OnInitialize()
	local LockedoutMo = LibStub( "LibDataBroker-1.1" ):NewDataObject( "Locked Out", {
		type = "data source",
		text = L[ "Locked Out" ],
		icon = "Interface\\Icons\\Inv_misc_key_10",
		OnClick = function( self ) addon:OpenConfigDialog( self ) end,
		OnEnter = function( self ) addon:ShowInfo( self ) end,
	} ); -- local LockedoutMo

	LockoutMapDb = LockoutMapDb or LibStub( "AceDB-3.0" ):New( "LockoutMapDb", { profile = { minimap = {hide = false } } } );
	icon:Register(addonName, LockedoutMo, LockoutMapDb.profile.minimap)

	self.optionFrameName = addonName .. "OptionPanel"
	LibStub( "AceConfigRegistry-3.0" ):RegisterOptionsTable( self.optionFrameName , options);
	self.optionFrame = LibStub( "AceConfigDialog-3.0" ):AddToBlizOptions( self.optionFrameName, addonName );
	self.optionFrame.default = function() self:ResetDefaults() end;
end

function addon:ResetDefaults()
	-- reset database here.
	print( "Implement default reset" );
	LibStub("AceConfigRegistry-3.0"):NotifyChange( self.optionFrameName );
end

function addon:OpenConfigDialog()
	InterfaceOptionsFrame_OpenToCategory( self.optionFrame );
end