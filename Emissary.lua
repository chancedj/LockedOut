--[[
    This file handles emissary tracking
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next = -- variables
      next   -- lua functions

-- cache blizzard function/globals
local GetQuestBountyInfoForMapID, GetQuestLogTitle, GetQuestLogIndexByID,
        GetQuestResetTime, GetServerTime, mfloor =                               -- variables 
      GetQuestBountyInfoForMapID, GetQuestLogTitle, GetQuestLogIndexByID,
        GetQuestResetTime, GetServerTime, math.floor                             -- blizzard api

local EMISSARY_MAP_ID = 1014;
local EMISSARY_LIST = {
    "48642", -- argussian reach
    "48641", -- armies of the legionfall
    "48639", -- armies of the light
    "42420", -- court of farondis
    "42233", -- highmountain tribes
    "42170", -- the dreamweavers
    "43179", -- kirin tor of dalaran
    "42421", -- the nightfallen
    "42234", -- the valajar   
    "42422" -- the wardens
}

local function copyEmissaryData( from, to )
    to.name       = from.name;
    to.day        = from.day;
    to.required   = from.fullfilled; -- set required to fulfilled.  we're only copying DONE data - so fulfilled and required need to be equal.
    to.fullfilled = from.fullfilled;
    to.resetDate  = from.resetDate;
end

function addon:Lockedout_BuildEmissary( realmName, charNdx )
    local emissaries = LockoutDb[ realmName ][ charNdx ].emissaries or {}; -- initialize world boss table;
    local dayCalc = 24 * 60 * 60;

    for _, questID in next, EMISSARY_LIST do
        ---[[
        local timeleft = C_TaskQuest.GetQuestTimeLeftMinutes( questID );
        local _, _, finished, numFulfilled, numRequired = GetQuestObjectiveInfo( questID, 1, false );
        if( timeleft ~= nil ) and ( timeleft > 0 ) and ( numRequired ~= nil ) then
            local day = mfloor( timeleft * 60 / dayCalc );
            local emissaryData = emissaries[ questID ] or {};
            local title = GetQuestLogTitle( GetQuestLogIndexByID( questID ) );
            
            emissaryData.name       = title;
            emissaryData.day        = day or 0;
            emissaryData.fullfilled = numFulfilled or 0;
            emissaryData.required   = numRequired or 0;
            emissaryData.isComplete = finished;
            emissaryData.resetDate  = GetServerTime() + GetQuestResetTime() + (day * dayCalc);
            
            emissaries[ questID ] = emissaryData;
        elseif( IsQuestFlaggedCompleted( questID ) ) and 
              ( ( emissaries[ questID ] == nil ) or ( emissaries[ questID ].isComplete ~= true ) ) then
            local emissaryData = emissaries[ questID ] or {};

            emissaryData.name       = emissaryData.name or nil;
            emissaryData.day        = emissaryData.day or 0;
            emissaryData.fullfilled = emissaryData.fullfilled or 0;
            emissaryData.required   = emissaryData.fullfilled or 0;
            emissaryData.isComplete = true;
            emissaryData.resetDate  = timeleft or (GetServerTime() + GetQuestResetTime());
            
            emissaries[ questID ] = emissaryData;
        end
        --]]
    end

    -- fix data that cannot be filled in on characters missing the emissary data
    -- copy it from other characters that know the current status of the quests.
    for questID, emissaryData in next, emissaries do
        local updated = false;

        -- update across empty buckets
        for rk, r in next, LockoutDb do
            for ck, c in next, r do
                -- skip yourself!
                if( realmName ~= rk ) and ( ck ~= charNdx ) then
                    if( emissaryData.name == nil ) then
                        if( c.emissaries ~= nil ) and ( c.emissaries[ questID ] ~= nil) and ( c.emissaries[ questID ].name ~= nil ) then
                            local copyFrom  = c.emissaries[ questID ];
                            copyEmissaryData( copyFrom, emissaryData );
                            updated = true;
                            break;
                        end
                    elseif ( c.emissaries ~= nil ) and ( c.emissaries[ questID ] ~= nil) and ( c.emissaries[ questID ].name == nil ) then
                        local copyTo  = c.emissaries[ questID ];
                        copyEmissaryData( emissaryData, copyTo );
                        updated = true;
                        break;
                    end
                end
            end
            if updated then break; end;
        end
    end
    
    LockoutDb[ realmName ][ charNdx ].emissaries = emissaries;
end -- Lockedout_BuildEmissary()
