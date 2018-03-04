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
        , GetQuestObjectiveInfo, GetServerTime, GetTime, GetTalentTreeIDsByClassID, GetTalentTreeInfoForID =                       -- variables 
      UnitClass, GetQuestBountyInfoForMapID, GetQuestLogTitle, GetQuestLogIndexByID, GetSpellCooldown
        , GetQuestObjectiveInfo, GetServerTime, GetTime, C_Garrison.GetTalentTreeIDsByClassID, C_Garrison.GetTalentTreeInfoForID   -- blizzard api

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";

local function checkQuestStatus( self )
    for _, questID in next, self.checkIDs do
        local resetDate;
        if( self.resetForm == "daily" ) then
            resetDate = addon:getDailyLockoutDate();
        elseif( self.resetForm == "weekly" ) then
            resetDate = addon:getWeeklyLockoutDate();
        else
            resetDate = nil
            print( "improper resetForm for questID: .. " .. questID );
        end

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

local QUEST_LIBRARY = {
    ["blingtron"]       = {name=L["Blingtron"],         startNdx=1, endNdx=1, resetForm="daily",  checkStatus=checkQuestStatus, copyAccountWide=true,  checkIDs={40753,34774,31752} },
    --[[
    spellID's for the below instance quests
    Death Knight: Frost Wyrm -- 221557
    Demon Hunter: Fel Hammer's Wrath -- 221561
    Mage: Might of Dalaran -- 221602
    Paladin: Grand Crusade -- 221587
    Warlock: Unleash Infernal -- 219540
    Warrior: Val'kyr Call -- 221597
    --]]
    ["instantquest"]        = {name=L["Instant Complete"],              startNdx=1, endNdx=1, resetForm="custom", checkStatus=checkSpellStatus, checkFullfilled=true,  copyAccountWide=false, checkIDs={219540,221557,221561,221587,221597,221602} },
    ["dalaranweekly"]       = {name=L["Dalaran Weekly"],                startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus, checkFullfilled=true,  copyAccountWide=false, checkIDs={44164,44173,44166,44167,45799,44171,44172,44174,44175} },
    ["seals"]               = {name=L["Seal of Fate"],                  startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus, checkFullfilled=true,  copyAccountWide=false, checkIDs={43510} },
    ["argusweekly"]         = {name=L["Argus - Pristine Argunite"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus, checkFullfilled=true,  copyAccountWide=false, checkIDs={48799} },
    ["argusinvasions"]      = {name=L["Argus - Invasions"],             startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus, checkFullfilled=true,  copyAccountWide=false, checkIDs={49293} },
    ["arguscridgestalker"]  = {name=L["Argus - Cheap Ridgestalker"],    startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus, checkFullfilled=false, copyAccountWide=false, checkIDs={48910} },
	["arguscvoidpurged"]    = {name=L["Argus - Cheap Void-Purged"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus, checkFullfilled=false, copyAccountWide=false, checkIDs={48911} },
	["argusclightforged"]   = {name=L["Argus - Cheap Lightforged"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus, checkFullfilled=false, copyAccountWide=false, checkIDs={48912} },
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
