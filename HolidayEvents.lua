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
local UnitClass, GetSpellCooldown, UnitFactionGroup
        , GetQuestObjectiveInfo, GetServerTime, GetTime, GetTalentTreeIDsByClassID, GetTalentTreeInfoForID, GetLFGDungeonRewards, IsQuestFlaggedCompleted  =                       -- variables 
      UnitClass, GetSpellCooldown, UnitFactionGroup
        , GetQuestObjectiveInfo, GetServerTime, GetTime, C_Garrison.GetTalentTreeIDsByClassID, C_Garrison.GetTalentTreeInfoForID, GetLFGDungeonRewards, C_QuestLog.IsQuestFlaggedCompleted    -- blizzard api

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";

local EVENTS_TO_TRACK = {
    -- brewfest
    [372] = {
        ["All"]         = {},
        ["Alliance"]    = {11293,11294,29394,12020},
        ["Horde"]       = {11407,11408,29393,12192},
    },
    -- feast of winter veil
    [141] = {
        ["All"]         = {39651,69649,69388,39648},
        ["Alliance"]    = {7043},
        ["Horde"]       = {6983},
    },
    -- hallows end
    [324] = {
        ["All"]         = {},
        ["Alliance"]    = {},
        ["Horde"]       = {},
    },
    -- love is in the air
    [335] = {
        ["All"]         = {},
        ["Alliance"]    = {},
        ["Horde"]       = {},
    },
    -- midsummer fire festival
    [341] = {
        ["All"]         = {11691,11924,11954},
        ["Alliance"]    = {},
        ["Horde"]       = {},
    },
    -- noblegarden
    [181] = {
        ["All"]         = {},
        ["Alliance"]    = {13480},
        ["Horde"]       = {13479},
    },
    -- pilgrims bounty
    [404] = {
        ["All"]         = {},
        ["Alliance"]    = {},
        ["Horde"]       = {},
    },

    -- recurring (monthly) events
    -- darkmoon faire
    [479] = {
        ["All"]         = {36481,29438,29463,29455,29436,37910,29434},
        ["Alliance"]    = {},
        ["Horde"]       = {},
    },
}

-- todo: combine wth Quests.Lua version...
local function checkQuestStatus( questID )
    local resetDate = addon:getDailyLockoutDate();

    if ( IsQuestFlaggedCompleted( questID ) ) then
        return resetDate, true, BOSS_KILL_TEXT;
    else
        local ndx = 1;
        local totalFullfilled, totalRequired = 0, 0;
        local _, _, _, numFulfilled, numRequired = GetQuestObjectiveInfo( questID, 1, false );
        if( numFulfilled ~= nil ) and ( numRequired ~= nil ) then
            totalFullfilled = totalFullfilled + numFulfilled;
            totalRequired   = totalRequired + numRequired;
        end
        
        if( totalRequired > 0 ) then
            return resetDate, (totalFullfilled == totalRequired), totalFullfilled .. "/" .. totalRequired;
        end
        
    end
    
    return 0, false, nil;
end

local function convertEventTime( eventTime )
    local ts = {
        year    = eventTime.year,
        month   = eventTime.month,
        day     = eventTime.monthDay,
        hour    = eventTime.hour,
        min     = eventTime.minute,
        sec     = 0
    };

    return time( ts );
end

function addon:Lockedout_GetCommingEvents()
    local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();
    local currentSetMonth, currentSetYear = currentCalendarTime.month, currentCalendarTime.year;

    local currentTime = GetServerTime();
    local currDp = date( "*t", currentTime );
    local endTime = addon:getDailyLockoutDate() + (2 * 7 * 24 * 60 * 60);
    local events = {};

    C_Calendar.SetAbsMonth( currDp.month, currDp.year );
    for offset = 0, 2 do 
        local monthInfo = C_Calendar.GetMonthInfo( 0 );
        local dayToUse  = 1;

        if( monthInfo.year == currDp.year ) and ( monthInfo.month == currDp.month ) then
            dayToUse = currDp.day;
        end;

        for day = dayToUse, monthInfo.numDays do
            local currentEventDate = time( { year=monthInfo.year, month=monthInfo.month, day=day } );

            if( currentEventDate > endTime ) then
                break;
            end;

            local eventCount = C_Calendar.GetNumDayEvents( 0, day );
            for eventNum = 1, eventCount do
                local eventInfo         = C_Calendar.GetDayEvent( 0, day, eventNum);
                local eventStartTime    = convertEventTime( eventInfo.startTime );
                local eventEndTime      = convertEventTime( eventInfo.endTime );

                if( EVENTS_TO_TRACK[ eventInfo.eventID ] ) and ( events[ eventInfo.eventID ] == nil ) then
                    EVENTS_TO_TRACK[ eventInfo.eventID ].title = eventInfo.title;
                    events[ eventInfo.eventID ] = {
                        startTime = eventStartTime,
                        endTime   = eventEndTime,
                        title     = eventInfo.title
                    };
                    addon:debug( "[", currentCalendarTime.month + offset, "/", day, " | ", eventInfo.eventID, " == ", eventInfo.title );
                end
            end
        end
        C_Calendar.SetMonth( 1 );
    end

    C_Calendar.SetAbsMonth( currentSetMonth, currentSetYear );
    return events;
end

local function getCurrentEvents()
    local aciveEvents = {};
    local currentEvents = addon:Lockedout_GetCommingEvents();

    local currentTime = GetServerTime();
    for eventID, eventData in next, currentEvents do
        addon:debug( "eventID: ", eventID, " start: ", date( "%x %X", eventData.startTime ), " end: ", date( "%x %X", eventData.endTime ) );
        if ( currentTime >= eventData.startTime) and ( currentTime <= eventData.endTime ) then
            aciveEvents[ eventID ] = eventData;
        end
    end

    return aciveEvents;
end

local function minDate( date1, date2 )
    if( date1 < date2 ) then
        return date1;
    else
        return date2;
    end
end

function addon:Lockedout_BuildHolidayEventQuests( )
    local holidayEvents = {}; -- initialize weekly quest table;
    
    local englishFaction = UnitFactionGroup("player")
    local activeEvents = getCurrentEvents();
    for currentEventID, eventInfo in next, activeEvents do
        local charEventData = {};
        local allQuests     = EVENTS_TO_TRACK[ currentEventID ][ "All" ] or {};
        local factionQuests = EVENTS_TO_TRACK[ currentEventID ][ englishFaction ] or {};
        
        allQuests = addon:mergeTable( allQuests, factionQuests );
        for _, questID in next, allQuests do
            local resetDate, completed, displayText = checkQuestStatus( questID );
            charEventData[ questID ] = {
                resetDate = minDate( eventInfo.endTime, resetDate ),
                completed = completed,
                displayText = displayText;
           }
        end

        holidayEvents[ currentEventID ] = charEventData;
    end

    addon.playerDb.holidayEvents = holidayEvents;
end -- Lockedout_BuildInstanceLockout()
