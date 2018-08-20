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
        , GetQuestObjectiveInfo, GetServerTime, GetTime, GetTalentTreeIDsByClassID, GetTalentTreeInfoForID, GetLFGDungeonRewards  =                       -- variables 
      UnitClass, GetQuestBountyInfoForMapID, GetQuestLogTitle, GetQuestLogIndexByID, GetSpellCooldown
        , GetQuestObjectiveInfo, GetServerTime, GetTime, C_Garrison.GetTalentTreeIDsByClassID, C_Garrison.GetTalentTreeInfoForID, GetLFGDungeonRewards    -- blizzard api

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";

local function getResetDateByForm( resetForm, questID )
    local resetDate;

    if( resetForm == "daily" ) then         resetDate = addon:getDailyLockoutDate();
    elseif( resetForm == "weekly" ) then    resetDate = addon:getWeeklyLockoutDate();
    else                                    resetDate = nil;    print( "improper resetForm for questID: ", questID ); end
    
    return resetDate;
end

local function checkQuestStatus( self )
    for _, questID in next, self.checkIDs do
        local resetDate = getResetDateByForm( self.resetForm, questID );

        if ( IsQuestFlaggedCompleted( questID ) ) then
            return resetDate, true, BOSS_KILL_TEXT;
        elseif( self.checkFullfilled ) then
            local ndx = 1;
            local totalFullfilled, totalRequired = 0, 0;
            -- quick hack to fix blizzards mess.
            for ndx=self.startNdx, self.endNdx do
                local _, _, _, numFulfilled, numRequired = GetQuestObjectiveInfo( questID, ndx, false );
                if( numFulfilled ~= nil ) then
                    totalFullfilled = totalFullfilled + numFulfilled;
                    totalRequired   = totalRequired + numRequired;
                end
            end
            
            if( totalFullfilled > 0 ) and (totalRequired > 0 ) then
                return resetDate, true, totalFullfilled .. "/" .. totalRequired;
            end
            
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
                for _, spellId in next, self.checkIDs do
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

local function checkDailyHeroicStatus( self )
    for _, questID in next, self.checkIDs do
        local resetDate = getResetDateByForm( self.resetForm, questID );

        local doneToday = GetLFGDungeonRewards( questID );
        
        if ( doneToday ) then
            return resetDate, doneToday, BOSS_KILL_TEXT;
        end
    end
    
    return 0, false, nil;
end

local QUEST_LIBRARY = {
    ["blingtron"]           = {name=L["Blingtron"],                     startNdx=1, endNdx=1, resetForm="daily",  checkStatus=checkQuestStatus,         checkFullfilled=false,  copyAccountWide=true,  checkIDs={40753,34774,31752} },
    ["dalaranweekly"]       = {name=L["Dalaran Weekly"],                startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={44164,44173,44166,44167,45799,44171,44172,44174,44175} },
    ["seals"]               = {name=L["Seal of Fate"],                  startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={43510} },
    ["argusweekly"]         = {name=L["Argus - Pristine Argunite"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={48799} },
    ["argusinvasions"]      = {name=L["Argus - Invasions"],             startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={49293} },
    ["arguscridgestalker"]  = {name=L["Argus - Cheap Ridgestalker"],    startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=false, copyAccountWide=false, checkIDs={48910} },
	["arguscvoidpurged"]    = {name=L["Argus - Cheap Void-Purged"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=false, copyAccountWide=false, checkIDs={48911} },
	["argusclightforged"]   = {name=L["Argus - Cheap Lightforged"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=false, copyAccountWide=false, checkIDs={48912} },
	["dailyheroic"]         = {name=L["Daily Heroic"],                  startNdx=1, endNdx=1, resetForm="daily",  checkStatus=checkDailyHeroicStatus,   checkFullfilled=false, copyAccountWide=false, checkIDs={50627} },
	["islandex"]            = {name=L["Island Expeditions"],            startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={53435, 53436} }
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
