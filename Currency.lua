--[[
    This file is to deal with the code to generate the lockout table/vector and
    to handle the refresh of data and deletion of stale data
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next, strfmt =            -- variables
      next, string.format       -- lua functions

-- cache blizzard function/globals
local GetCurrencyInfo, GetItemCount, IsQuestFlaggedCompleted =    -- variables
      GetCurrencyInfo, GetItemCount, IsQuestFlaggedCompleted      -- blizzard api

---[[
local BONUS_ROLL_QUESTID = {
    [ 1273 ] = {
        [1] = {
            43892,  -- order resources
            43893,  -- order resources
            43894,  -- order resources
            43895,  -- gold
            43896,  -- gold
            43897,  -- gold
            47851,  -- marks of honor
            47864,  -- marks of honor
            47865,  -- marks of honor
            --43510,  -- class hall
            47040,  -- broken shore
            47045,  -- broken shore
            47054   -- broken shore

        }
    },
    [ 1580 ] = {
        [1] = {
            52837,  -- resources
            52840,  -- resources
            52834,  -- gold
            52838,  -- gold
            52835,  -- marks of honor
            52839,  -- marks of honor
        }
    }

}
--]]

local shortMap = {
    [1] =
        {
            limit = 1e9, -- billions
            fmt = "%.1fb"
        },
    [2] =
        {
            limit = 1e6, -- millions
            fmt = "%.1fm"
        },
    [3] =
        {
            limit = 1e3, -- thousands
            fmt = "%.1fk"
        }
}

function addon:shortenAmount( amount )
    local result = amount

    if( self.config.profile.currency.display == "short" ) then
        for _, map in next, shortMap do
            if( amount > map.limit ) then
                return strfmt( map.fmt, amount / map.limit );
            end
        end
    end
    
    return result;
end

function addon:Lockedout_BuildCurrencyList( )
    local currency = {}; -- initialize currency table;

    for ndx, currencyData in next, addon:getCurrencyList() do
        if( currencyData.show ) then
            local count, maximum, discovered;
            if( currencyData.type == "C" ) then
                _, count, _, _, _, maximum, discovered = GetCurrencyInfo( currencyData.ID );
            else
                count = GetItemCount( currencyData.ID, true, false );
                discovered = (count > 0);
                maximum = 0;
            end;

            local data;
            if( discovered ) then
                data = {
                    count = count,
                    maximum = maximum
                }
                
                local questList = BONUS_ROLL_QUESTID[ currencyData.ID ];
                local bonus;
                if( questList ~= nil ) then
                    data.resetDate = self:getWeeklyLockoutDate();
                    bonus = {};
                    for _, questGroup in next, questList do
                        for _, questID in next, questGroup do
                            addon:getQuestTitleByID( questID ); -- call now to cache the data for later
                            addon:debug( "checking: " .. questID );
                            if( IsQuestFlaggedCompleted( questID ) ) then
                                addon:debug( "complete: " .. questID );
                                bonus[ #bonus + 1 ] = questID;
                            end
                        end
                    end
                end
                
                data.bonus = bonus;
            else
                data = nil;
            end
            
            currency[ currencyData.ID ] = data;
        end
    end

    addon.playerDb.currency = currency;
end -- Lockedout_BuildInstanceLockout()
