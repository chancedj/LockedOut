--[[
    This file is for overall helper functions that are to be used addon wide.
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- cache lua functions
local print, type, tonumber =                      -- variables
      print, type, tonumber                        -- lua functions

-- cache blizzard function/globals
local GetCurrentRegion, GetServerTime, GetCurrencyInfo, GetQuestResetTime, GetItemInfo,
        EJ_SelectInstance, EJ_GetEncounterInfoByIndex, RAID_CLASS_COLORS =                          -- variables
      GetCurrentRegion, GetServerTime, GetCurrencyInfo, GetQuestResetTime, GetItemInfo,
        EJ_SelectInstance, EJ_GetEncounterInfoByIndex, CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;    -- blizzard global table

addon.ExpansionAbbr = {
    [0] = L["Van"],
    [1] = L["BC"],
    [2] = L["WotLK"],
    [3] = L["Cata"],
    [4] = L["MoP"],
    [5] = L["WoD"],
    [6] = L["Leg"],
    [7] = L["BfA"],
}

addon.KEY_KEYSTONE = "keystone";
addon.KEY_MYTHICBEST = "mythicbest";

local iconTextures = {
    ["134244"]  = "|T" .. "134244" .. ":0|t",
    ["237446"]  = "|T" .. "237446" .. ":0|t",
    ["1397630"] = "|T" .. "1397630" .. ":0|t",
    ["132998"]  = "|T" .. "132998" .. ":0|t",
    ["133278"]  = "|T" .. "133278" .. ":0|t",
    ["1500867"] = "|T" .. "1500867" .. ":0|t",
    ["133413"]  = "|T" .. "133413" .. ":0|t",
    ["134245"]  = "|T" .. "134245" .. ":0|t",
    ["132761"]  = "|T" .. "132761" .. ":0|t",
    ["237284"]  = "|T" .. "237284" .. ":0|t",
    ["237285"]  = "|T" .. "237285" .. ":0|t",
    ["134532"]  = "|T" .. "134532" .. ":0|t",
    ["237379"]  = "|T" .. "237379" .. ":0|t",
    ["1508506"] = "|T" .. "1508506" .. ":0|t",
    ["1516058"] = "|T" .. "1516058" .. ":0|t"
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
    -- currency
    { ID=1,    name=nil, icon=nil, expansionLevel=1, type="C", show=false }, -- Currency Token Test Token 4
    { ID=2,    name=nil, icon=nil, expansionLevel=1, type="C", show=false }, -- Currency Token Test Token 2
    { ID=4,    name=nil, icon=nil, expansionLevel=1, type="C", show=false }, -- Currency Token Test Token 5
    { ID=22,   name=nil, icon=nil, expansionLevel=1, type="C", show=false }, -- Birmingham Test Item 3
    { ID=42,   name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Badge of Justice
    { ID=61,   name=nil, icon=nil, expansionLevel=2, type="C", show=true }, -- Dalaran Jewelcrafter's Token
    { ID=81,   name=nil, icon=nil, expansionLevel=2, type="C", show=true }, -- Epicurean's Award
    { ID=101,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Emblem of Heroism
    { ID=102,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Emblem of Valor
    { ID=103,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Arena Points
    { ID=104,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Honor Points DEPRECATED
    { ID=121,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Alterac Valley Mark of Honor
    { ID=122,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Arathi Basin Mark of Honor
    { ID=123,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Eye of the Storm Mark of Honor
    { ID=124,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Strand of the Ancients Mark of Honor
    { ID=125,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Warsong Gulch Mark of Honor
    { ID=126,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Wintergrasp Mark of Honor
    { ID=161,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Stone Keeper's Shard
    { ID=181,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Honor Points DEPRECATED2
    { ID=201,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Venture Coin
    { ID=221,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Emblem of Conquest
    { ID=241,  name=nil, icon=nil, expansionLevel=2, type="C", show=true }, -- Champion's Seal
    { ID=301,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Emblem of Triumph
    { ID=321,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Isle of Conquest Mark of Honor
    { ID=341,  name=nil, icon=nil, expansionLevel=2, type="C", show=false }, -- Emblem of Frost
    { ID=361,  name=nil, icon=nil, expansionLevel=3, type="C", show=true }, -- Illustrious Jewelcrafter's Token
    { ID=384,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Dwarf Archaeology Fragment
    { ID=385,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Troll Archaeology Fragment
    { ID=391,  name=nil, icon=nil, expansionLevel=3, type="C", show=true }, -- Tol Barad Commendation
    { ID=393,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Fossil Archaeology Fragment
    { ID=394,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Night Elf Archaeology Fragment
    { ID=395,  name=nil, icon=nil, expansionLevel=3, type="C", show=true }, -- Justice Points
    { ID=396,  name=nil, icon=nil, expansionLevel=3, type="C", show=true }, -- Valor Points
    { ID=397,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Orc Archaeology Fragment
    { ID=398,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Draenei Archaeology Fragment
    { ID=399,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Vrykul Archaeology Fragment
    { ID=400,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Nerubian Archaeology Fragment
    { ID=401,  name=nil, icon=nil, expansionLevel=3, type="C", show=false }, -- Tol'vir Archaeology Fragment
    { ID=402,  name=nil, icon=nil, expansionLevel=3, type="C", show=true }, -- Ironpaw Token
    { ID=416,  name=nil, icon=nil, expansionLevel=3, type="C", show=true }, -- Mark of the World Tree
    { ID=483,  name=nil, icon=nil, expansionLevel=1, type="C", show=true }, -- Conquest Arena Meta
    { ID=484,  name=nil, icon=nil, expansionLevel=1, type="C", show=true }, -- Conquest Rated BG Meta
    { ID=515,  name=nil, icon=nil, expansionLevel=1, type="C", show=true }, -- Darkmoon Prize Ticket
    { ID=614,  name=nil, icon=nil, expansionLevel=3, type="C", show=true }, -- Mote of Darkness
    { ID=615,  name=nil, icon=nil, expansionLevel=3, type="C", show=true }, -- Essence of Corrupted Deathwing
    { ID=676,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Pandaren Archaeology Fragment
    { ID=677,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Mogu Archaeology Fragment
    { ID=692,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Conquest Random BG Meta
    { ID=697,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Elder Charm of Good Fortune
    { ID=698,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Zen Jewelcrafter's Token
    { ID=738,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Lesser Charm of Good Fortune
    { ID=752,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Mogu Rune of Fate
    { ID=754,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Mantid Archaeology Fragment
    { ID=776,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Warforged Seal
    { ID=777,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Timeless Coin
    { ID=789,  name=nil, icon=nil, expansionLevel=4, type="C", show=true }, -- Bloody Coin
    { ID=810,  name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Black Iron Fragment
    { ID=821,  name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Draenor Clans Archaeology Fragment
    { ID=823,  name=nil, icon=nil, expansionLevel=5, type="C", show=true }, -- Apexis Crystal
    { ID=824,  name=nil, icon=nil, expansionLevel=5, type="C", show=true }, -- Garrison Resources
    { ID=828,  name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Ogre Archaeology Fragment
    { ID=829,  name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Arakkoa Archaeology Fragment
    { ID=830,  name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- n/a
    { ID=897,  name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- UNUSED
    { ID=910,  name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Secret of Draenor Alchemy
    { ID=944,  name=nil, icon=nil, expansionLevel=5, type="C", show=true }, -- Artifact Fragment
    { ID=980,  name=nil, icon=nil, expansionLevel=5, type="C", show=true }, -- Dingy Iron Coins
    { ID=994,  name=nil, icon=nil, expansionLevel=5, type="C", show=true }, -- Seal of Tempered Fate
    { ID=999,  name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Secret of Draenor Tailoring
    { ID=1008, name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Secret of Draenor Jewelcrafting
    { ID=1017, name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Secret of Draenor Leatherworking
    { ID=1020, name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Secret of Draenor Blacksmithing
    { ID=1101, name=nil, icon=nil, expansionLevel=5, type="C", show=true }, -- Oil
    { ID=1129, name=nil, icon=nil, expansionLevel=5, type="C", show=true }, -- Seal of Inevitable Fate
    { ID=1149, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Sightless Eye
    { ID=1154, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Shadowy Coins
    { ID=1155, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Ancient Mana
    { ID=1171, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Artifact Knowledge
    { ID=1172, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Highborne Archaeology Fragment
    { ID=1173, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Highmountain Tauren Archaeology Fragment
    { ID=1174, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Demonic Archaeology Fragment
    { ID=1191, name=nil, icon=nil, expansionLevel=5, type="C", show=false }, -- Valor
    { ID=1220, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Order Resources
    { ID=1226, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Nethershard
    { ID=1268, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Timeworn Artifact
    { ID=1273, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Seal of Broken Fate
    { ID=1275, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Curious Coin
    { ID=1299, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Brawler's Gold
    { ID=1314, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Lingering Soul Fragment
    { ID=1324, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Horde Qiraji Commendation
    { ID=1325, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Alliance Qiraji Commendation
    { ID=1342, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Legionfall War Supplies
    { ID=1347, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Legionfall Building - Personal Tracker - Mage Tower (Hidden)
    { ID=1349, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Legionfall Building - Personal Tracker - Command Tower (Hidden)
    { ID=1350, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Legionfall Building - Personal Tracker - Nether Tower (Hidden)
    { ID=1355, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Felessence
    { ID=1356, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Echoes of Battle
    { ID=1357, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Echoes of Domination
    { ID=1379, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Trial of Style Token
    { ID=1416, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Coins of Air
    { ID=1501, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- Writhing Essence
    { ID=1506, name=nil, icon=nil, expansionLevel=6, type="C", show=false }, -- Argus Waystone
    { ID=1508, name=nil, icon=nil, expansionLevel=6, type="C", show=true },  -- Veiled Argunite
    { ID=1533, name=nil, icon=nil, expansionLevel=6, type="C", show=true },  -- Wakening Essence
    
    -- new BFA  currency.  Not sure which yet are hidden and which should be displayed.
    -- using best guess (based on previous expansion currencies) to set flag.
    { ID=1388, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Armor Scraps 
    { ID=1401, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Stronghold Supplies 
    { ID=1534, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Zandalari Archaeology Fragment 
    { ID=1535, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Drust Archaeology Fragment 
    { ID=1540, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Wood 
    { ID=1541, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Iron 
    { ID=1553, name=nil, icon=nil, expansionLevel=7, type="C", show=true }, -- Azerite 
    { ID=1559, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Essence of Storms 
    { ID=1560, name=nil, icon=nil, expansionLevel=7, type="C", show=true }, -- War Resources 
    { ID=1565, name=nil, icon=nil, expansionLevel=7, type="C", show=true }, -- Rich Azerite Fragment 
    { ID=1579, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Champions of Azeroth 
    { ID=1580, name=nil, icon=nil, expansionLevel=7, type="C", show=true }, -- Seal of Wartorn Fate 
    { ID=1585, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Honor 
    { ID=1586, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Honor Level 
    { ID=1587, name=nil, icon=nil, expansionLevel=7, type="C", show=true }, -- War Supplies 
    { ID=1592, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Order of Embers 
    { ID=1593, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Proudmore Admiralty 
    { ID=1594, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Storm's Wake 
    { ID=1595, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Talanji's Expedition 
    { ID=1596, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Voldunai 
    { ID=1597, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Zandalari Empire 
    { ID=1598, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Tortollan Seekers 
    { ID=1599, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- 7th Legion 
    { ID=1600, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Honorbound 
    { ID=1602, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Conquest 
    { ID=1703, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- BFA Season 1 Rated Participation Currency 
    { ID=1704, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Spirit Shard 
    { ID=1705, name=nil, icon=nil, expansionLevel=7, type="C", show=false }, -- Warfronts - Personal Tracker - Iron in Chest (Hidden) 
    { ID=1710, name=nil, icon=nil, expansionLevel=7, type="C", show=true },  -- Seafarer's Dubloon

    -- items
    { ID=116415, name=nil, icon=nil, expansionLevel=6, type="I", show=true },  -- Pet Charm
    { ID=124124, name=nil, icon=nil, expansionLevel=6, type="I", show=true },  -- Blood of Sargeras
    { ID=151568, name=nil, icon=nil, expansionLevel=6, type="I", show=true },  -- Primal Sargerite
    
    -- currencies that extend beyond expansions (expansionLevel should always be == current
    { ID=1166, name=nil, icon=nil, expansionLevel=7, type="C", show=true }, -- Timewarped Badge

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

local characterSortOptions = {
    ["rc"] = {
        description = L["Realm then Name"],
        sortFunction =  function(l, r)
                            if (l.priority ~= r.priority) then
                                return l.priority < r.priority;
                            end
                            
                            if (l.realmName ~= r.realmName) then
                                return l.realmName < r.realmName;
                            end
                            
                            return l.charName < r.charName;
                         end
    },
    ["cr"] = {
        description = L["Name then Realm"],
        sortFunction =  function(l, r)
                            if (l.priority ~= r.priority) then
                                return l.priority < r.priority;
                            end
                            
                            if (l.charName ~= r.charName) then
                                return l.charName < r.charName;
                            end
                            
                            return l.realmName < r.realmName;
                        end
    }
}

local function resolveCurrencyInfo( )
    for _, currency in next, CURRENCY_LIST do
        if( currency.name == nil ) or ( currency.icon == nil ) then
            if( currency.type == "C" ) then
                currency.name, _, currency.icon = GetCurrencyInfo( currency.ID );
            else
                currency.name, _, _, _, _, _, _, _, _, currency.icon = GetItemInfo( currency.ID );
            end;
            
            if( currency.icon ) then
                currency.icon = "|T" .. currency.icon .. ":0|t"
            end
        end
    end
end

local MyScanningTooltip = CreateFrame("GameTooltip", "MyScanningTooltip", UIParent, "GameTooltipTemplate")

local QuestTitleFromID = setmetatable({}, { __index = function(t, id)
	MyScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	MyScanningTooltip:SetHyperlink("quest:"..id)
	local title = MyScanningTooltipTextLeft1:GetText()
	MyScanningTooltip:Hide()
	if title and title ~= RETRIEVING_DATA then
		t[id] = title
		return title
	end
end })

function addon:getQuestTitleByID( questID )
    -- example pulled from below
    -- http://www.wowinterface.com/forums/showthread.php?t=46934
    return QuestTitleFromID[ questID ];
end

function addon:getWorldBossName( sInstanceID, sBossID )
    local iInstanceID = tonumber( sInstanceID );
    local iBossID = tonumber( sBossID );

    EJ_SelectInstance( iInstanceID );

    local bossNdx = 1;
    local bossName, _, bossID = EJ_GetEncounterInfoByIndex( bossNdx );
    while bossID do
        if( bossID == iBossID ) then
            return bossName
        end
        
        bossNdx = bossNdx + 1;
        bossName, _, bossID = EJ_GetEncounterInfoByIndex( bossNdx );
    end
    
    return "unknown";
end

function addon:debug( msg )
    if( false ) then
        print( msg );
    end;
end

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

function addon:getCharacterList()
    local charList = {};
    
    if( LockoutDb == nil ) then return charList; end;
    
    for realmName, characters in next, LockoutDb do
        for charNdx, charData in next, characters do
            if (charData.charName ~= nil) then
                charList[ realmName .. "." .. charData.charName ] = realmName .. " - " .. charData.charName;
            end
        end
    end

    return charList;
end

function addon:getCurrencyOptions()
    return currencySortOptions;
end

function addon:getCharSortOptions()
    return characterSortOptions;
end

function addon:getIconOptions()
    return iconTextures;
end

function addon:getCurrencyListMap()
    local map = {};
    
    for ndx, curr in next, CURRENCY_LIST do
        map[ curr.ID ] = ndx;
    end
    
    return map;
end

function addon:getCurrencyList()
    resolveCurrencyInfo();
    
    return CURRENCY_LIST;
end

function addon:getDailyLockoutDate()
    return GetServerTime() + GetQuestResetTime();
end

function addon:getWeeklyLockoutDate()
    local secondsInDay      = 24 * 60 * 60;
    local serverResetDay    = MapRegionReset[ GetCurrentRegion() ];
    local currentServerTime = GetServerTime();
    local daysLefToReset    = weekdayRemap[ serverResetDay ][ date( "*t", currentServerTime ).wday ];
    local weeklyResetTime   = self:getDailyLockoutDate();

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

local function fif( value, t, f )
    if( value ) then
        return t;
    else
        return f;
    end;
end

--- recursive printing for debug purposes
function addon:printTable( tbl, maxDepth, depth )
	if ( tbl == nil ) then return; end
	if ( maxDepth ~= nil ) and ( depth == maxDepth ) then return; end
	
	depth = depth or 0; -- initialize depth to 0 if nil
	local indent = strrep( "  ", depth ) .. "=>";
	
	for key, value in next, tbl do
		if ( type ( value ) == "table" ) then
			print( indent .. key );

			-- initialize depth to 0 if nil
			self:printTable( value, maxDepth, depth + 1 );
		elseif( type( value ) == "boolean" ) then
			print( indent .. key .. " - " .. fif( value, "true", "false" ) );
		elseif( type( value ) == "function" ) then
			print( indent .. key .. " = " .. value() );
		else
			print( indent .. key .. " - " .. value );
		end -- if ( type ( value ) == "table" )
	end -- for key, value in next, tbl
	
end 
