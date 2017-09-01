--[[
	This file is to deal with the code to generate the lockout table/vector and
	to handle the refresh of data and deletion of stale data
--]]
local addonName, addonHelpers = ...;

-- libraries
local L = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next = -- variables
	  next	  -- lua functions

-- cache blizzard function/globals
local GetCurrencyListSize, GetCurrencyListInfo =	-- variables 
	  GetCurrencyListSize, GetCurrencyListInfo		-- blizzard api

function Lockedout_BuildCurrentList( realmName, charNdx, playerData )
	local currency = {}; -- initialize currency table;
	
	playerData.currency = currency;
end -- Lockedout_BuildInstanceLockout()
