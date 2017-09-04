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
	[ "Seal of Broken Fate" ] = { 43892, 43893, 43894, 43895, 43896, 43897, 47851, 47864, 47865, 47040, 47045, 47054 }
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
				local bonusCompleted = 0;
				for _, questId in next, questList do
					if( IsQuestFlaggedCompleted( questId ) ) then
						bonusCompleted = bonusCompleted + 1;
					end
				end
				currency[ name ].resetDate = calculatedResetDate;
				currency[ name ].displayTextAddl = "(" .. bonusCompleted  .. ")";
			end
		end
	end
	
	playerData.currency = currency;
end -- Lockedout_BuildInstanceLockout()
