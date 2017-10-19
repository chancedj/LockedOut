--[[
    This file is for overall helper functions that are to be used addon wide.
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- cache lua functions
local print, type =                                -- variables
      print, type                                  -- lua functions

-- cache blizzard function/globals
local GetCurrentRegion, GetServerTime, GetQuestResetTime, RAID_CLASS_COLORS =                        -- variables
      GetCurrentRegion, GetServerTime, GetQuestResetTime, CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS; -- blizzard global table

function addon:colorizeString( className, value )
    if( className == nil ) then return value; end

    local sStart, sTail, classColor = "|c", "|r", RAID_CLASS_COLORS[ className ].colorStr;

    return sStart .. classColor .. value .. sTail;
end -- addon:colorizeString

function addon:destroyDb()
    if( LockoutDb == nil ) then return; end

    local _, charData = next( LockoutDb );
    if( charData == nil ) then LockoutDb = nil; return; end

    local key = next( charData );
    -- if the char ndx is not a number, we have the old style so destroy db
    if( type( key ) ~= "number" ) then LockoutDb = nil; end;
end -- destroyDb

addon.ExpansionAbbr = {
    [0] = L["Van"],
    [1] = L["BC"],
    [2] = L["WotLK"],
    [3] = L["Cata"],
    [4] = L["MoP"],
    [5] = L["WoD"],
    [6] = L["Leg"],    
}

-- tues for US, Wed for rest?
local MapRegionReset = {
    [1] = 3, -- US
    [2] = 5, -- KR
    [3] = 4, -- EU
    [4] = 5, -- TW
    [5] = 5  -- CN
}

local weekdayRemap = {
    [3] = {
        [1] = 1,
        [2] = 0,
        [3] = 6,
        [4] = 5,
        [5] = 4,
        [6] = 3,
        [7] = 2,
    },
    [4] = {
        [1] = 2,
        [2] = 1,
        [3] = 0,
        [4] = 6,
        [5] = 5,
        [6] = 4,
        [7] = 3,
    },
    [5] = {
        [1] = 3,
        [2] = 2,
        [3] = 1,
        [4] = 0,
        [5] = 6,
        [6] = 5,
        [7] = 4,
    },
}

local CURRENCY_LIST = {
    { currencyID=1,    name=nil, icon=nil, expansionLevel=1, show=false }, -- Currency Token Test Token 4
    { currencyID=2,    name=nil, icon=nil, expansionLevel=1, show=false }, -- Currency Token Test Token 2
    { currencyID=4,    name=nil, icon=nil, expansionLevel=1, show=false }, -- Currency Token Test Token 5
    { currencyID=22,   name=nil, icon=nil, expansionLevel=1, show=false }, -- Birmingham Test Item 3
    { currencyID=42,   name=nil, icon=nil, expansionLevel=2, show=false }, -- Badge of Justice
    { currencyID=61,   name=nil, icon=nil, expansionLevel=2, show=true }, -- Dalaran Jewelcrafter's Token
    { currencyID=81,   name=nil, icon=nil, expansionLevel=2, show=true }, -- Epicurean's Award
    { currencyID=101,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Emblem of Heroism
    { currencyID=102,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Emblem of Valor
    { currencyID=103,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Arena Points
    { currencyID=104,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Honor Points DEPRECATED
    { currencyID=121,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Alterac Valley Mark of Honor
    { currencyID=122,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Arathi Basin Mark of Honor
    { currencyID=123,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Eye of the Storm Mark of Honor
    { currencyID=124,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Strand of the Ancients Mark of Honor
    { currencyID=125,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Warsong Gulch Mark of Honor
    { currencyID=126,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Wintergrasp Mark of Honor
    { currencyID=161,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Stone Keeper's Shard
    { currencyID=181,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Honor Points DEPRECATED2
    { currencyID=201,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Venture Coin
    { currencyID=221,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Emblem of Conquest
    { currencyID=241,  name=nil, icon=nil, expansionLevel=2, show=true }, -- Champion's Seal
    { currencyID=301,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Emblem of Triumph
    { currencyID=321,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Isle of Conquest Mark of Honor
    { currencyID=341,  name=nil, icon=nil, expansionLevel=2, show=false }, -- Emblem of Frost
    { currencyID=361,  name=nil, icon=nil, expansionLevel=3, show=true }, -- Illustrious Jewelcrafter's Token
    { currencyID=384,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Dwarf Archaeology Fragment
    { currencyID=385,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Troll Archaeology Fragment
    { currencyID=391,  name=nil, icon=nil, expansionLevel=3, show=true }, -- Tol Barad Commendation
    { currencyID=393,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Fossil Archaeology Fragment
    { currencyID=394,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Night Elf Archaeology Fragment
    { currencyID=395,  name=nil, icon=nil, expansionLevel=3, show=true }, -- Justice Points
    { currencyID=396,  name=nil, icon=nil, expansionLevel=3, show=true }, -- Valor Points
    { currencyID=397,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Orc Archaeology Fragment
    { currencyID=398,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Draenei Archaeology Fragment
    { currencyID=399,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Vrykul Archaeology Fragment
    { currencyID=400,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Nerubian Archaeology Fragment
    { currencyID=401,  name=nil, icon=nil, expansionLevel=3, show=false }, -- Tol'vir Archaeology Fragment
    { currencyID=402,  name=nil, icon=nil, expansionLevel=3, show=true }, -- Ironpaw Token
    { currencyID=416,  name=nil, icon=nil, expansionLevel=3, show=true }, -- Mark of the World Tree
    { currencyID=483,  name=nil, icon=nil, expansionLevel=1, show=true }, -- Conquest Arena Meta
    { currencyID=484,  name=nil, icon=nil, expansionLevel=1, show=true }, -- Conquest Rated BG Meta
    { currencyID=515,  name=nil, icon=nil, expansionLevel=1, show=true }, -- Darkmoon Prize Ticket
    { currencyID=614,  name=nil, icon=nil, expansionLevel=3, show=true }, -- Mote of Darkness
    { currencyID=615,  name=nil, icon=nil, expansionLevel=3, show=true }, -- Essence of Corrupted Deathwing
    { currencyID=676,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Pandaren Archaeology Fragment
    { currencyID=677,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Mogu Archaeology Fragment
    { currencyID=692,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Conquest Random BG Meta
    { currencyID=697,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Elder Charm of Good Fortune
    { currencyID=698,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Zen Jewelcrafter's Token
    { currencyID=738,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Lesser Charm of Good Fortune
    { currencyID=752,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Mogu Rune of Fate
    { currencyID=754,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Mantid Archaeology Fragment
    { currencyID=776,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Warforged Seal
    { currencyID=777,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Timeless Coin
    { currencyID=789,  name=nil, icon=nil, expansionLevel=4, show=true }, -- Bloody Coin
    { currencyID=810,  name=nil, icon=nil, expansionLevel=5, show=false }, -- Black Iron Fragment
    { currencyID=821,  name=nil, icon=nil, expansionLevel=5, show=false }, -- Draenor Clans Archaeology Fragment
    { currencyID=823,  name=nil, icon=nil, expansionLevel=5, show=true }, -- Apexis Crystal
    { currencyID=824,  name=nil, icon=nil, expansionLevel=5, show=true }, -- Garrison Resources
    { currencyID=828,  name=nil, icon=nil, expansionLevel=5, show=false }, -- Ogre Archaeology Fragment
    { currencyID=829,  name=nil, icon=nil, expansionLevel=5, show=false }, -- Arakkoa Archaeology Fragment
    { currencyID=830,  name=nil, icon=nil, expansionLevel=5, show=false }, -- n/a
    { currencyID=897,  name=nil, icon=nil, expansionLevel=5, show=false }, -- UNUSED
    { currencyID=910,  name=nil, icon=nil, expansionLevel=5, show=false }, -- Secret of Draenor Alchemy
    { currencyID=944,  name=nil, icon=nil, expansionLevel=5, show=true }, -- Artifact Fragment
    { currencyID=980,  name=nil, icon=nil, expansionLevel=5, show=true }, -- Dingy Iron Coins
    { currencyID=994,  name=nil, icon=nil, expansionLevel=5, show=true }, -- Seal of Tempered Fate
    { currencyID=999,  name=nil, icon=nil, expansionLevel=5, show=false }, -- Secret of Draenor Tailoring
    { currencyID=1008, name=nil, icon=nil, expansionLevel=5, show=false }, -- Secret of Draenor Jewelcrafting
    { currencyID=1017, name=nil, icon=nil, expansionLevel=5, show=false }, -- Secret of Draenor Leatherworking
    { currencyID=1020, name=nil, icon=nil, expansionLevel=5, show=false }, -- Secret of Draenor Blacksmithing
    { currencyID=1101, name=nil, icon=nil, expansionLevel=5, show=true }, -- Oil
    { currencyID=1129, name=nil, icon=nil, expansionLevel=5, show=true }, -- Seal of Inevitable Fate
    { currencyID=1149, name=nil, icon=nil, expansionLevel=6, show=true }, -- Sightless Eye
    { currencyID=1154, name=nil, icon=nil, expansionLevel=6, show=true }, -- Shadowy Coins
    { currencyID=1155, name=nil, icon=nil, expansionLevel=6, show=true }, -- Ancient Mana
    { currencyID=1166, name=nil, icon=nil, expansionLevel=6, show=true }, -- Timewarped Badge
    { currencyID=1171, name=nil, icon=nil, expansionLevel=6, show=false }, -- Artifact Knowledge
    { currencyID=1172, name=nil, icon=nil, expansionLevel=6, show=false }, -- Highborne Archaeology Fragment
    { currencyID=1173, name=nil, icon=nil, expansionLevel=6, show=false }, -- Highmountain Tauren Archaeology Fragment
    { currencyID=1174, name=nil, icon=nil, expansionLevel=6, show=false }, -- Demonic Archaeology Fragment
    { currencyID=1191, name=nil, icon=nil, expansionLevel=5, show=false }, -- Valor
    { currencyID=1220, name=nil, icon=nil, expansionLevel=6, show=true }, -- Order Resources
    { currencyID=1226, name=nil, icon=nil, expansionLevel=6, show=true }, -- Nethershard
    { currencyID=1268, name=nil, icon=nil, expansionLevel=6, show=true }, -- Timeworn Artifact
    { currencyID=1273, name=nil, icon=nil, expansionLevel=6, show=true }, -- Seal of Broken Fate
    { currencyID=1275, name=nil, icon=nil, expansionLevel=6, show=true }, -- Curious Coin
    { currencyID=1299, name=nil, icon=nil, expansionLevel=6, show=true }, -- Brawler's Gold
    { currencyID=1314, name=nil, icon=nil, expansionLevel=6, show=true }, -- Lingering Soul Fragment
    { currencyID=1324, name=nil, icon=nil, expansionLevel=6, show=false }, -- Horde Qiraji Commendation
    { currencyID=1325, name=nil, icon=nil, expansionLevel=6, show=false }, -- Alliance Qiraji Commendation
    { currencyID=1342, name=nil, icon=nil, expansionLevel=6, show=true }, -- Legionfall War Supplies
    { currencyID=1347, name=nil, icon=nil, expansionLevel=6, show=false }, -- Legionfall Building - Personal Tracker - Mage Tower (Hidden)
    { currencyID=1349, name=nil, icon=nil, expansionLevel=6, show=false }, -- Legionfall Building - Personal Tracker - Command Tower (Hidden)
    { currencyID=1350, name=nil, icon=nil, expansionLevel=6, show=false }, -- Legionfall Building - Personal Tracker - Nether Tower (Hidden)
    { currencyID=1355, name=nil, icon=nil, expansionLevel=6, show=true }, -- Felessence
    { currencyID=1356, name=nil, icon=nil, expansionLevel=6, show=true }, -- Echoes of Battle
    { currencyID=1357, name=nil, icon=nil, expansionLevel=6, show=true }, -- Echoes of Domination
    { currencyID=1379, name=nil, icon=nil, expansionLevel=6, show=true }, -- Trial of Style Token
    { currencyID=1416, name=nil, icon=nil, expansionLevel=6, show=true }, -- Coins of Air
    { currencyID=1501, name=nil, icon=nil, expansionLevel=6, show=true }, -- Writhing Essence
    { currencyID=1506, name=nil, icon=nil, expansionLevel=6, show=false }, -- Argus Waystone
    { currencyID=1508, name=nil, icon=nil, expansionLevel=6, show=true }  -- Veiled Argunite
};

local currencySortOptions = {
    ["en"] = {
        description = L["Expansion then Name"],
        sortFunction =  function(l, r)
                            if ( l.expansionLevel ~= r.expansionLevel ) then
                                return l.expansionLevel > r.expansionLevel;
                            end

                            return l.name < r.name;
                        end
    },
    ["ne"] = {
        description = L["Name then Expansion"],
        sortFunction =  function(l, r)
                            if ( l.name ~= r.name ) then
                                return l.name < r.name;
                            end

                            return l.expansionLevel > r.expansionLevel;
                        end
    }
}

local function resolveCurrencyInfo( )
    for _, currency in next, CURRENCY_LIST do
        currency.name, _, currency.icon = GetCurrencyInfo( currency.currencyID );
        
        if( currency.icon ) then
            currency.icon = "|T" .. currency.icon .. ":0|t"
        end
    end
end

function addon:getCurrencyOptions()
    return currencySortOptions;
end

function addon:getCurrencyListMap()
    local map = {};
    
    for ndx, curr in next, CURRENCY_LIST do
        map[ curr.currencyID ] = ndx;
    end
    
    return map;
end

function addon:getCurrencyList()
    local _, data = next( CURRENCY_LIST );
    
    -- make sure this is only done once
    if( data.name == nil ) then
        resolveCurrencyInfo();
    end
    
    return CURRENCY_LIST;
end

function addon:getDailyLockoutDate()
    return GetServerTime() + GetQuestResetTime();
end

function addon:getWeeklyLockoutDate()
    local secondsInDay      = 24 * 60 * 60;
    local serverResetDay    = MapRegionReset[ GetCurrentRegion() ];
    local daysLefToReset    = weekdayRemap[ serverResetDay ][ date( "*t", currentServerTime ).wday ];

    local currentServerTime = GetServerTime();
    local weeklyResetTime   = addon:getDailyLockoutDate();

    -- handle reset on day of reset (before vs after server reset)
    if( daysLefToReset == 6 ) then
        -- if they are diff, we've passed server reset time.  so push it a week.
        if( date("%x", weeklyResetTime) ~= date("%x", currentServerTime) ) then
            weeklyResetTime = weeklyResetTime + (daysLefToReset * secondsInDay);
        end
    else
        weeklyResetTime = weeklyResetTime + (daysLefToReset * secondsInDay);
    end

    return weeklyResetTime
end
