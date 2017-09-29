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

local configOptions = {
	type = "group",
	name = addonName,
	args = {
		enableAddon = {
		  order = 1,
		  name = "Enable",
		  desc = "Enables / disables the addon",
		  type = "toggle",
		  set = function(info,val) LockoutMapDb.profile.enabled = val; end,
		  get = function(info) return LockoutMapDb.profile.enabled end
		},
		generalHeader={
		  order = 10,
		  name = "General Options",
		  type = "header",
		},
		currentRealmOnly = {
		  order = 11,
		  name = "Current Realm",
		  desc = "Show characters from current realm only",
		  type = "toggle",
		  set = function(info,val) LockoutMapDb.profile.general.currentRealm = val; end,
		  get = function(info) return LockoutMapDb.profile.general.currentRealm end
		},
		showMinimapIcon = {
		  order = 12,
		  name = "Hide Icon",
		  desc = "Show Minimap Icon",
		  type = "toggle",
		  set = function(info,val) LockoutMapDb.profile.minimap.hide = val; end,
		  get = function(info) return LockoutMapDb.profile.minimap.hide end
		},
		dungeonHeader={
		  order = 20,
		  name = "Instance Options",
		  type = "header",
		},
		dungeonShow = {
		  order = 21,
		  name = "Show",
		  desc = "Show dungeon information",
		  type = "toggle",
		  set = function(info,val) LockoutMapDb.profile.dungeon.show = val; end,
		  get = function(info) return LockoutMapDb.profile.dungeon.show end
		},
		raidHeader={
		  order = 30,
		  name = "Raid Options",
		  type = "header",
		},
		raidShow = {
		  order = 31,
		  name = "Show",
		  desc = "Show raid information",
		  type = "toggle",
		  set = function(info,val) LockoutMapDb.profile.raid.show = val; end,
		  get = function(info) return LockoutMapDb.profile.raid.show end
		},
		worldBossHeader={
		  order = 40,
		  name = "World Boss Options",
		  type = "header",
		},
		worldBossShow = {
		  order = 41,
		  name = "Show",
		  desc = "Show world boss information",
		  type = "toggle",
		  set = function(info,val) LockoutMapDb.profile.worldBoss.show = val; end,
		  get = function(info) return LockoutMapDb.profile.worldBoss.show end
		},
		currencyHeader={
		  order = 50,
		  name = "Currency Options",
		  type = "header",
		},
		currencyShow = {
		  order = 51,
		  name = "Show",
		  desc = "Show currency information",
		  type = "toggle",
		  set = function(info,val) LockoutMapDb.profile.currency.show = val; end,
		  get = function(info) return LockoutMapDb.profile.currency.show end
		},
	}
};

local defaultOptions = {
	profile = {
		enabled = true,
		minimap = {
			hide = false
		},
		general = {
			currentRealm = false
		},
		dungeon = {
			show = true
		},
		raid = {
			show = true
		},
		worldBoss = {
			show = true
		},
		currency = {
			show = true
		}
	}
}

function addon:OnInitialize()
	local LockedoutMo = LibStub( "LibDataBroker-1.1" ):NewDataObject( "Locked Out", {
		type = "data source",
		text = L[ "Locked Out" ],
		icon = "Interface\\Icons\\Inv_misc_key_10",
		OnClick = function( self ) addon:OpenConfigDialog( self ) end,
		OnEnter = function( self ) addon:ShowInfo( self ) end,
	} ); -- local LockedoutMo

	LockoutMapDb = LibStub( "AceDB-3.0" ):New( addonName .. "Db", defaultOptions, true );
	LockoutMapDb:RegisterDefaults( defaultOptions );
	icon:Register(addonName, LockedoutMo, LockoutMapDb.profile.minimap)

	self.optionFrameName = addonName .. "OptionPanel"
	LibStub( "AceConfigRegistry-3.0" ):RegisterOptionsTable( self.optionFrameName , configOptions);
	self.optionFrame = LibStub( "AceConfigDialog-3.0" ):AddToBlizOptions( self.optionFrameName, addonName );
	self.optionFrame.default = function() self:ResetDefaults() end;
end

function addon:ResetDefaults()
	-- reset database here.
	LockoutMapDb:ResetProfile();
	LibStub("AceConfigRegistry-3.0"):NotifyChange( self.optionFrameName );
end

function addon:OpenConfigDialog()
	InterfaceOptionsFrame_OpenToCategory( self.optionFrame );
end