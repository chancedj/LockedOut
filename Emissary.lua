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
local GetQuestObjectiveInfo, GetQuestTimeLeftMinutes =                               -- variables 
      GetQuestObjectiveInfo, C_TaskQuest.GetQuestTimeLeftMinutes                     -- blizzard api

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
    { questID = "42422", numRequired=4 }  -- the wardens
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
    local dailyResetDate = addon:getDailyLockoutDate();
    
    for _, emData in next, EMISSARY_LIST do
        ---[[
        local questID = emData.questID;
        local timeleft = GetQuestTimeLeftMinutes( questID );
        local _, _, finished, numFulfilled, numRequired = GetQuestObjectiveInfo( questID, 1, false );
        if( timeleft ~= nil ) and ( timeleft > 0 ) and ( numRequired ~= nil ) then
            local day = mfloor( timeleft * 60 / dayCalc );
            local emissaryData = emissaries[ questID ] or {};
            
            emissaryData.fullfilled = numFulfilled or 0;
            emissaryData.required   = numRequired or 0;
            emissaryData.isComplete = finished;
            emissaryData.resetDate  = dailyResetDate + (day * dayCalc);
            
            self:debug( "In Process: ", questID );
            emissaries[ questID ] = emissaryData;
        elseif( IsQuestFlaggedCompleted( questID ) ) then
            local emissaryData = emissaries[ questID ] or {};
            local resetDate = emissaryData.resetDate or dailyResetDate;
            
            if( timeleft ~= nil) and (timeleft > 0 ) then
                local day = mfloor( timeleft * 60 / dayCalc );
                resetDate = dailyResetDate + (day * dayCalc)
            end
            
            emissaryData.fullfilled = emData.numRequired;
            emissaryData.required   = emData.numRequired;
            emissaryData.isComplete = true;
            emissaryData.resetDate  = resetDate;
            
            self:debug( "Completed: resetDate: ", emissaryData.resetDate, "timeleft: ", timeleft, " - ", questID );
            emissaries[ questID ] = emissaryData;
        else
            emissaries[ questID ] = nil;
        end
        --]]
    end

    -- fix nil error on char rebuild
    LockoutDb[ realmName ][ charNdx ].emissaries = emissaries;
    for realmName, charDataList in next, LockoutDb do
        for charNdx, charData in next, charDataList do
            local charEmissaries = charData.emissaries;
            for questID, emissaryData in next, emissaries do
                if( charEmissaries[ questID ] ~= nil ) then
                    if( charEmissaries[ questID ].resetDate < emissaries[ questID ].resetDate ) then
                        self:debug( "updating: ", realmName, " - ", charData.charName );
                        charEmissaries[ questID ].resetDate = emissaries[ questID ].resetDate;
                    elseif( charEmissaries[ questID ].resetDate > emissaries[ questID ].resetDate ) then
                        self:debug( "using: ", realmName, " - ", charData.charName );
                        emissaries[ questID ].resetDate = charEmissaries[ questID ].resetDate;
                    end
                end               
            end
        end
    end
    
    -- last update since we may have updated
    LockoutDb[ realmName ][ charNdx ].emissaries = emissaries;
end -- Lockedout_BuildEmissary()
