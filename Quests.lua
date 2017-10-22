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
local UnitClass, GetQuestBountyInfoForMapID, GetQuestLogTitle, GetQuestLogIndexByID, GetSpellCooldown
        , GetServerTime, GetTime, GetTalentTreeIDsByClassID, GetTalentTreeInfoForID =                       -- variables 
      UnitClass, GetQuestBountyInfoForMapID, GetQuestLogTitle, GetQuestLogIndexByID, GetSpellCooldown
        , GetServerTime, GetTime, C_Garrison.GetTalentTreeIDsByClassID, C_Garrison.GetTalentTreeInfoForID   -- blizzard api

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";

local function checkQuestStatus( self )
    for _, questId in next, self.checkIDs do
        if ( IsQuestFlaggedCompleted( questId ) ) then
            local resetDate;
            if( self.resetForm == "daily" ) then
                resetDate = addon:getDailyLockoutDate();
            elseif( self.resetForm == "weekly" ) then
                resetDate = addon:getWeeklyLockoutDate();
            else
                resetDate = nil
                print( "improper resetForm for questId: .. " .. questId );
            end
            
            return resetDate, true, BOSS_KILL_TEXT;
        end
    end
    
    return 0, false, nil;
end

local function checkSpellStatus( self )
    local _, _, classType = UnitClass( "player" );
    local talentTreeIDs = GetTalentTreeIDsByClassID(LE_GARRISON_TYPE_7_0, classType)
    
    -- not working properly, so disable for now.
    if( talentTreeIDs ) then
        local _, treeID = next(talentTreeIDs);
        local _, _, tree = GetTalentTreeInfoForID( treeID );
        
        for ndx, data in next, tree do
            if( data.selected ) then
                for _, spellId in next, self.checkIds do
                    if( data.perkSpellID == spellId ) then
                        local start, duration, enabled = GetSpellCooldown( spellId );
                        
                        -- when enabled == 1, it's not ready, meaning it's on cooldown
                        if( start > 0 ) and ( enabled == 1 ) then
                            return GetServerTime() + ((start + duration) - GetTime()), true, BOSS_KILL_TEXT;
                        end
                        
                        break;
                    end
                end
            end
        end
    end
    
    return 0, false, nil;
end

local QUEST_LIBRARY = {
    ["blingtron"]       = {name=L["Blingtron"],         resetForm="daily",  checkStatus=checkQuestStatus, copyAccountWide=true,  checkIDs={40753,34774,31752} },
    ["instantquest"]    = {name=L["Instant Complete"],  resetForm="custom", checkStatus=checkSpellStatus, copyAccountWide=false, checkIDs={219540,221597,221557} },
    ["dalaranweekly"]   = {name=L["Dalaran Weekly"],    resetForm="weekly", checkStatus=checkQuestStatus, copyAccountWide=false, checkIDs={44164,44173,44166,44167,45799,44171,44172,44174,44175} }
};

function addon:Lockedout_BuildWeeklyQuests( realmName, charNdx )
    local weeklyQuests = {}; -- initialize weekly quest table;

    local calculatedResetDate = addon:getWeeklyLockoutDate();
    for abbr, questData in next, QUEST_LIBRARY do
        local resetDate, completed, displayText = questData:checkStatus();

        local indivQuestData = nil;
        if( completed ) then
            indivQuestData = {};
            indivQuestData.name = questData.name;
            indivQuestData.displayText = displayText;
            indivQuestData.resetDate = resetDate;
        end

        weeklyQuests[ abbr ] = indivQuestData;
        if( questData.copyAccountWide ) then
            -- blingtron is account bound, so we copy across the accounts
            for realmName, characters in next, LockoutDb do
                for charNdx, charData in next, characters do
                    charData.weeklyQuests = charData.weeklyQuests or {};
                    charData.weeklyQuests[ abbr ] = indivQuestData;
                end
            end
        end
    end -- for bossId, bossData in next, WORLD_BOSS_LIST
 
    LockoutDb[ realmName ][ charNdx ].weeklyQuests = weeklyQuests;
end -- Lockedout_BuildInstanceLockout()
