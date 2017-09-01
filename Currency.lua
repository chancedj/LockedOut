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
	
	local currencyListSize = GetCurrencyListSize();
	for index=1, currencyListSize do
		local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum = GetCurrencyListInfo(index);
		
		if( not isHeader ) and ( not isUnused ) then
			currency[ name ] = {}
			if( maximum > 0 ) then
				currency[ name ].displayText = count .. "/" .. maximum;
			else
				currency[ name ].displayText = count;
			end
		end
	end
	
	playerData.currency = currency;
end -- Lockedout_BuildInstanceLockout()
