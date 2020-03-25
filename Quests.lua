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
local UnitClass, GetSpellCooldown, GetQuestObjectiveInfo, GetServerTime, GetLFGDungeonRewards  =                       -- variables 
      UnitClass, GetSpellCooldown, GetQuestObjectiveInfo, GetServerTime, GetLFGDungeonRewards    -- blizzard api

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";

local function getResetDateByForm( resetForm, questID )
    local resetDate;

    if( resetForm == "daily" ) then         resetDate = addon:getDailyLockoutDate();
    elseif( resetForm == "weekly" ) then    resetDate = addon:getWeeklyLockoutDate();
    else                                    resetDate = nil;    print( L["Improper resetForm for questID: "], questID ); end
    
    return resetDate;
end

-- todo: combine wth HolidayEvents.Lua version...
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
    ["blingtron"]           = {name=L["Blingtron"],                     startNdx=1, endNdx=1, resetForm="daily",  checkStatus=checkQuestStatus,         checkFullfilled=false, copyAccountWide=true,  checkIDs={40753,34774,31752} },
    ["cityweekly"]          = {name=L["Main City Weekly"],              startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={53032,53036,53033,53034,53035,53037,53039,53038,53030} },
    ["seals"]               = {name=L["Seal of Fate"],                  startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={43510} },
    ["argusweekly"]         = {name=L["Argus - Pristine Argunite"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={48799} },
    ["argusinvasions"]      = {name=L["Argus - Invasions"],             startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={49293} },
    ["arguscridgestalker"]  = {name=L["Argus - Cheap Ridgestalker"],    startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=false, copyAccountWide=false, checkIDs={48910} },
    ["arguscvoidpurged"]    = {name=L["Argus - Cheap Void-Purged"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=false, copyAccountWide=false, checkIDs={48911} },
    ["argusclightforged"]   = {name=L["Argus - Cheap Lightforged"],     startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=false, copyAccountWide=false, checkIDs={48912} },
    ["dailyheroic"]         = {name=L["Daily Heroic"],                  startNdx=1, endNdx=1, resetForm="daily",  checkStatus=checkDailyHeroicStatus,   checkFullfilled=false, copyAccountWide=false, checkIDs={50627} },
    ["islandex"]            = {name=L["Island Expeditions"],            startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={53435, 53436} },
	["minorvision"]         = {name=L["N\'Zoth Minor Vision"],          startNdx=1, endNdx=1, resetForm="daily",  checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={58168, 58155, 58151, 58167, 58156} },
	["majorassault"]        = {name=L["Major N\'Zoth Assault"],         startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={57157, 56064} },
	["minorassault"]        = {name=L["Minor N\'Zoth Assault"],         startNdx=1, endNdx=1, resetForm="weekly", checkStatus=checkQuestStatus,         checkFullfilled=true,  copyAccountWide=false, checkIDs={57008, 57728, 55350, 56308} }
	
	
};

function addon:Lockedout_BuildWeeklyQuests( )
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
 
    addon.playerDb.weeklyQuests = weeklyQuests;
end -- Lockedout_BuildInstanceLockout()
