--[[
    This file handles emissary tracking
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next, mfloor =    -- variables
      next, math.floor  -- lua functions

-- cache blizzard function/globals
local GetQuestBountyInfoForMapID, GetQuestLogTitle, GetQuestLogIndexByID,
        GetQuestResetTime, GetServerTime, GetQuestObjectiveInfo, GetQuestTimeLeftMinutes =                               -- variables 
      GetQuestBountyInfoForMapID, GetQuestLogTitle, GetQuestLogIndexByID,
        GetQuestResetTime, GetServerTime, GetQuestObjectiveInfo, C_TaskQuest.GetQuestTimeLeftMinutes                     -- blizzard api

local EMISSARY_MAP_ID = 1014;
local EMISSARY_LIST = {
    { questID = "48642", numRequired=4 }, -- argussian reach
    { questID = "48641", numRequired=4 }, -- armies of the legionfall
    { questID = "48639", numRequired=4 }, -- armies of the light
    { questID = "42420", numRequired=4 }, -- court of farondis
    { questID = "42233", numRequired=4 }, -- highmountain tribes
    { questID = "42170", numRequired=4 }, -- the dreamweavers
    { questID = "43179", numRequired=3 }, -- kirin tor of dalaran
    { questID = "42421", numRequired=4 }, -- the nightfallen
    { questID = "42234", numRequired=4 }, -- the valajar   
    { questID = "42422", numRequired=4 } -- the wardens
}

local function copyEmissaryData( from, to )
    to.name       = from.name;
    to.required   = from.fullfilled; -- set required to fulfilled.  we're only copying DONE data - so fulfilled and required need to be equal.
    to.fullfilled = from.fullfilled;
    to.resetDate  = from.resetDate;
end

function addon:Lockedout_BuildEmissary( realmName, charNdx )
    local emissaries = LockoutDb[ realmName ][ charNdx ].emissaries or {}; -- initialize world boss table;
    local dayCalc = 24 * 60 * 60;

    for _, emData in next, EMISSARY_LIST do
        ---[[
        local questID = emData.questID;
        local timeleft = GetQuestTimeLeftMinutes( questID );
        local _, _, finished, numFulfilled, numRequired = GetQuestObjectiveInfo( questID, 1, false );
        if( timeleft ~= nil ) and ( timeleft > 0 ) and ( numRequired ~= nil ) then
            local day = mfloor( timeleft * 60 / dayCalc );
            local emissaryData = emissaries[ questID ] or {};
            local title = GetQuestLogTitle( GetQuestLogIndexByID( questID ) );
            
            emissaryData.name       = title;
            emissaryData.fullfilled = numFulfilled or 0;
            emissaryData.required   = numRequired or 0;
            emissaryData.isComplete = finished;
            emissaryData.resetDate  = addon:getDailyLockoutDate() + (day * dayCalc);
            
            print( "In Process: " .. addon:getQuestTitleByID( questID ) );
            emissaries[ questID ] = emissaryData;
        elseif( IsQuestFlaggedCompleted( questID ) ) then
            local emissaryData = emissaries[ questID ] or {};
            local title = GetQuestLogTitle( GetQuestLogIndexByID( questID ) );

            emissaryData.name       = title;
            emissaryData.fullfilled = emData.numRequired;
            emissaryData.required   = emData.numRequired;
            emissaryData.isComplete = true;
            emissaryData.resetDate  = timeleft or emissaryData.resetDate or addon:getDailyLockoutDate();
            
            emissaries[ questID ] = emissaryData;
        end
        --]]
    end
    
    LockoutDb[ realmName ][ charNdx ].emissaries = emissaries;
end -- Lockedout_BuildEmissary()
