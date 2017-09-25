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
local GetCurrencyListSize, GetCurrencyListInfo, IsQuestFlaggedCompleted =	-- variables 
	  GetCurrencyListSize, GetCurrencyListInfo, IsQuestFlaggedCompleted		-- blizzard api

---[[
local BONUS_ROLL_QUESTID = {
	[ "Seal of Broken Fate" ] = {
		[1] = {
			43892,	-- order resources
			43893,	-- order resources
			43894,	-- order resources
			43895,	-- gold
			43896,	-- gold
			43897,	-- gold
			47851,	-- marks of honor
			47864,	-- marks of honor
			47865,	-- marks of honor
			43510,	-- class hall
			47040,	-- broken shore
			47045,	-- broken shore
			47054	-- broken shore

		}
	}
}
--]]

function Lockedout_BuildCurrentList( realmName, charNdx, playerData )
	local currency = {}; -- initialize currency table;
	
	local currencyListSize = GetCurrencyListSize();
	local calculatedResetDate = addonHelpers:getWeeklyLockoutDate();
	for index=1, currencyListSize do
		local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum = GetCurrencyListInfo(index);
		
		if( not isHeader ) and ( not isUnused ) then
			currency[ name ] = {}
			if( maximum > 0 ) then
				currency[ name ].displayText = count .. "/" .. maximum;
			else
				currency[ name ].displayText = count;
			end
			
			local questList = BONUS_ROLL_QUESTID[ name ];
			if( questList ~= nil ) then
				local bonus = {};
				for _, questGroup in next, questList do
					local bonusCompleted = 0;
					for _, questId in next, questGroup do
						if( IsQuestFlaggedCompleted( questId ) ) then
							bonusCompleted = bonusCompleted + 1;
						end
					end
					
					bonus[ #bonus + 1 ] = bonusCompleted;
				end
				currency[ name ].resetDate = calculatedResetDate;
				currency[ name ].displayTextAddl = "(" .. table.concat( bonus, "/" ) .. ")";
			end
		end
	end
	
	playerData.currency = currency;
end -- Lockedout_BuildInstanceLockout()
