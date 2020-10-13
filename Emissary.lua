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
local GetQuestObjectiveInfo, GetQuestTimeLeftMinutes, C_GetFactionParagonInfo, C_IsFactionParagon, IsQuestFlaggedCompleted =                                    -- variables 
      GetQuestObjectiveInfo, C_TaskQuest.GetQuestTimeLeftMinutes, C_Reputation.GetFactionParagonInfo, C_Reputation.IsFactionParagon, C_QuestLog.IsQuestFlaggedCompleted    -- blizzard api

--[[
    first key is the expansion level that the emissary applies to
    second key is the questid that the emissary ties to
--]]
local EMISSARY_LIST = {
    [ "6" ] = {
        [ "48642" ] = { numRequired=4, factionId=2170 }, -- argussian reach
        [ "48641" ] = { numRequired=4, factionId=2045 }, -- armies of the legionfall
        [ "48639" ] = { numRequired=4, factionId=2165 }, -- armies of the light
        [ "42420" ] = { numRequired=4, factionId=1900 }, -- court of farondis
        [ "42233" ] = { numRequired=4, factionId=1828 }, -- highmountain tribes
        [ "42170" ] = { numRequired=4, factionId=1883 }, -- the dreamweavers
        [ "43179" ] = { numRequired=3, factionId=1090 }, -- kirin tor of dalaran
        [ "42421" ] = { numRequired=4, factionId=1859 }, -- the nightfallen
        [ "42234" ] = { numRequired=4, factionId=1948 }, -- the valajar   
        [ "42422" ] = { numRequired=4, factionId=1894 }  -- the wardens
    },
    [ "7" ] = {
        [ "50604" ] = { numRequired=3, factionId=2163 }, -- Tortollan Seekers (neutral)
        [ "50562" ] = { numRequired=4, factionId=2164 }, -- Champions of Azeroth (neutral)
        [ "50599" ] = { numRequired=4, factionId=2160 }, -- Proudmoore Admiralty (alliance)
        [ "50600" ] = { numRequired=4, factionId=2161 }, -- Order of Embers (alliance)
        [ "50601" ] = { numRequired=4, factionId=2162 }, -- Storm's Wake (alliance)
        [ "50605" ] = { numRequired=4, factionId=2159 }, -- Alliance War Effort (alliance)
        [ "50598" ] = { numRequired=4, factionId=2103 }, -- Zandalari Empire (horde)
        [ "50603" ] = { numRequired=4, factionId=2158 }, -- Voldunai (horde)
        [ "50602" ] = { numRequired=4, factionId=2156 }, -- Talanji's Expedition (horde)
        [ "50606" ] = { numRequired=4, factionId=2157 }, -- Horde War Effort (horde)
        [ "56119" ] = { numRequired=4, factionId=2400 }, -- The Waveblade Akoan (alliance)
        [ "56120" ] = { numRequired=4, factionId=2373 }  -- The Unshackled (horde)
    }
}

local function copyEmissaryData( from, to )
    to.name       = from.name;
    to.required   = from.fullfilled; -- set required to fulfilled.  we're only copying DONE data - so fulfilled and required need to be equal.
    to.fullfilled = from.fullfilled;
    to.resetDate  = from.resetDate;
end

function addon:Lockedout_BuildEmissary( )
    local emissaries = addon.playerDb.emissaries or {}; -- initialize world boss table;
    local dayCalc = 24 * 60 * 60;
    local dailyResetDate = addon:getDailyLockoutDate();
    
    for expLevel, emExpansionList in next, EMISSARY_LIST do
        for questID, emData in next, emExpansionList do
            ---[[
            --local questID = emData.questID;
            local timeleft = GetQuestTimeLeftMinutes( questID );
            local _, _, finished, numFulfilled, numRequired = GetQuestObjectiveInfo( questID, 1, false );
            local factionParagonEnabled = C_IsFactionParagon( emData.factionId );
            local currentValue, threshold, _, hasRewardPending = C_GetFactionParagonInfo( emData.factionId );

            self:debug( 'factionId: ', emData.factionId, ' ',  currentValue, '/', threshold, ' Reward Pending: ', factionParagonEnabled and hasRewardPending );
            
            local emissaryData = emissaries[ questID ] or {};

            if( timeleft ~= nil ) and ( timeleft > 0 ) and ( numRequired ~= nil ) then
                local day = mfloor( timeleft * 60 / dayCalc );
                
                emissaryData.active       = true;
                emissaryData.fullfilled   = numFulfilled or 0;
                emissaryData.required     = numRequired or 0;
                emissaryData.isComplete   = finished and IsQuestFlaggedCompleted( questID );
                emissaryData.resetDate    = dailyResetDate + (day * dayCalc);
                emissaryData.paragonReady = factionParagonEnabled and hasRewardPending;
                emissaryData.expLevel     = expLevel;
                
                self:debug( "In Process: ", questID );
            elseif( IsQuestFlaggedCompleted( questID ) ) then
                local resetDate = emissaryData.resetDate or dailyResetDate;
                
                if( timeleft ~= nil) and (timeleft > 0 ) then
                    local day = mfloor( timeleft * 60 / dayCalc );
                    resetDate = dailyResetDate + (day * dayCalc)
                end
                
                emissaryData.active         = true;
                emissaryData.fullfilled     = emData.numRequired;
                emissaryData.required       = emData.numRequired;
                emissaryData.isComplete     = true;
                emissaryData.resetDate      = resetDate;
                emissaryData.paragonReady   = factionParagonEnabled and hasRewardPending;
                emissaryData.expLevel       = expLevel;
                
                self:debug( "Completed: resetDate: ", emissaryData.resetDate, "timeleft: ", timeleft, " - ", questID );
            elseif( factionParagonEnabled and hasRewardPending ) then
                emissaryData.active         = false;
                emissaryData.fullfilled     = 0;
                emissaryData.required       = 0;
                emissaryData.isComplete     = false;
                emissaryData.resetDate      = -1;
                emissaryData.paragonReady   = factionParagonEnabled and hasRewardPending;
                emissaryData.expLevel       = expLevel;
                
                self:debug( "Paragon found: ", questID );
            else
                emissaryData = nil;
            end
            --]]
            emissaries[ questID ] = emissaryData;
        end
    end

    -- fix nil error on char rebuild
    addon.playerDb.emissaries = emissaries;
    for realmName, charDataList in next, LockoutDb do
        for charNdx, charData in next, charDataList do
            local charEmissaries = charData.emissaries;
            
            for questID, emissaryData in next, emissaries do
                if( charEmissaries[ questID ] ~= nil ) then
                    local charEmissaryData = charEmissaries[ questID ];
                    if( charEmissaryData.resetData ) and (charEmissaryData.resetData == -1) then
                        --- skip - paragon is tracking only for current char, so don't copy!;
                    elseif( charEmissaryData.resetDate < emissaries[ questID ].resetDate ) then
                        self:debug( "updating: ", realmName, " - ", charData.charName );
                        charEmissaryData.resetDate = emissaries[ questID ].resetDate;
                        charEmissaryData.active    = emissaries[ questID ].active;
                        charEmissaryData.expLevel  = emissaries[ questID ].expLevel;
                    elseif( charEmissaryData.resetDate > emissaries[ questID ].resetDate ) then
                        self:debug( "using: ", realmName, " - ", charData.charName );
                        emissaries[ questID ].resetDate = charEmissaryData.resetDate;
                        emissaries[ questID ].active    = charEmissaryData.active;
                        emissaries[ questID ].expLevel  = charEmissaryData.expLevel;
                    end
                end
            end
        end
    end
    
    -- last update since we may have updated
    addon.playerDb.emissaries = emissaries;
end -- Lockedout_BuildEmissary()
