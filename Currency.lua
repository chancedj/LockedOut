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
local GetCurrencyInfo, IsQuestFlaggedCompleted =    -- variables
      GetCurrencyInfo, IsQuestFlaggedCompleted      -- blizzard api

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
            43510,  -- class hall
            47040,  -- broken shore
            47045,  -- broken shore
            47054   -- broken shore

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

function addon:Lockedout_BuildCurrencyList( realmName, charNdx )
    local currency = {}; -- initialize currency table;

    for ndx, currencyData in next, addon:getCurrencyList() do
        if( currencyData.show ) then
            local name, count, icon, _, _, maximum, discovered = GetCurrencyInfo( currencyData.currencyID );

            local data;
            if( discovered ) then
                data = {
                    count = count,
                    maximum = maximum
                }
                
                local questList = BONUS_ROLL_QUESTID[ currencyData.currencyID ];
                local bonus;
                if( questList ~= nil ) then
                    bonus = {};
                    for _, questGroup in next, questList do
                        local bonusCompleted = 0;
                        for _, questId in next, questGroup do
                            if( IsQuestFlaggedCompleted( questId ) ) then
                                bonusCompleted = bonusCompleted + 1;
                            end
                        end

                        bonus[ #bonus + 1 ] = bonusCompleted;
                    end
                end
                
                data.bonus = bonus;
            else
                data = nil;
            end
            
            currency[ currencyData.currencyID ] = data;
        end
    end

    LockoutDb[ realmName ][ charNdx ].currency = currency;
end -- Lockedout_BuildInstanceLockout()
