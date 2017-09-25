--[[
	This file is to deal with the code to generate the lockout table/vector and
	to handle the refresh of data and deletion of stale data
--]]
local addonName, addon = ...;

-- libraries
LibStub( "AceAddon-3.0" ):NewAddon( addon, addonName );
local L = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

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

function addon:OnInitialize()
	print( "addon initialized ... " );
end

LibStub( "AceConfigRegistry-3.0" ):RegisterOptionsTable( addonName .. "Panel" , options);
LibStub( "AceConfigDialog-3.0" ):AddToBlizOptions( addonName .. "Panel", addonName );
