--[[
    This file is to deal with the code to generate the lockout table/vector and
    to handle the refresh of data and deletion of stale data
--]]
local addonName, _ = ...;

-- libraries
local addon     = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L         = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );
local LibQTip   = LibStub( "LibQTip-1.0" )

-- cache blizzard function/globals
local GetRealmName, UnitName, UnitClass, GetAverageItemLevel =  -- variables 
      GetRealmName, UnitName, UnitClass, GetAverageItemLevel;   -- blizzard api

--[[
    this will generate the saved data for characters and realms
    
    the data is stored in this way [key] (prop1, prop2, ...):
    
    [realmName]
        [playerNdx] (charName, className,currIlvl, maxIlvl, instances)
            instances() = [instanceName]
                            [difficultyName] (bossData, locked, displayText)
                                [bossNdx] (bossName, isKilled)
            worldbosses() = [bossName]
    
--]]

local function getCharIndex( characters, search_charName )
    local charNdx = #characters + 1;

    for searchNdx, character in next, characters do
        if( search_charName == character.charName ) then
            return searchNdx;
        end; -- if( search_charName == character.charName )
    end -- for searchNdx, character in next, characters
    
    return charNdx;
end -- getCharIndex()

local function clearExpiredLockouts( dataTable )
    if( dataTable == nil ) then return; end
    local currentServerTime = GetServerTime();
    
    for key, data in next, dataTable do
        if( data.resetDate == nil ) or ( data.resetDate < currentServerTime ) then
            dataTable[ key ] = nil;
        end -- if( data.resetDate == nil ) or ( data.resetDate < currentServerTime )
    end -- for key, data in next, dataTable
end -- clearExpiredLockouts()

local function clearCurrencyQuests( dataTable )
    if( dataTable == nil ) then return; end
    local currentServerTime = GetServerTime();

    for _, currData in next, dataTable do
        currData.displayText = nil;
        currData.displayAddlText = nil;
        if( currData.resetDate ~= nil) and ( currData.resetDate < currentServerTime ) then
            currData.bonus = {};
        end
    end
end

local function checkExpiredLockouts()
    -- if we add a new element, it will be empty for the charData
    -- take care of this by exiting.
    if( LockoutDb == nil ) then return; end
    
    for realmName, characters in next, LockoutDb do
        for charNdx, charData in next, characters do
            -- initialize data if necessary
            charData.instances      = charData.instances or {};
            charData.worldBosses    = charData.worldBosses or {};
            charData.emissaries     = charData.emissaries or {};
            charData.currency       = charData.currency or {};
            charData.weeklyQuests   = charData.weeklyQuests or {};

            if( charData.instances ~= nil ) then
                for instanceName, instanceData in next, charData.instances do
                    clearExpiredLockouts( instanceData );
                    
                    -- if the data expired and emptys our table, clear the instance table
                    local key = next(instanceData);
                    if( key == nil ) then
                        charData.instances[ instanceName ] = nil;
                    end
                end
            end
            
            clearExpiredLockouts( charData.worldBosses );
            clearExpiredLockouts( charData.emissaries );
            clearExpiredLockouts( charData.weeklyQuests );
            clearCurrencyQuests( charData.currency );
        end -- for charNdx, charData in next, characters
    end -- for realmName, charData in next, LockoutDb
end -- checkExpiredLockouts()

function addon:Lockedout_GetCurrentCharData()
    addon:destroyDb();
    checkExpiredLockouts();
    
    -- get and initialize realm data
    local realmName = GetRealmName();
    LockoutDb = LockoutDb or {};                            -- initialize database if not already initialized
    LockoutDb[ realmName ] = LockoutDb[ realmName ] or {};    -- initialize realmDb if not already initialized

    -- get and initialize character data
    local charName = UnitName( "player" );
    local _, className = UnitClass( "player" );
    local charNdx = getCharIndex( LockoutDb[ realmName ], charName );
    local playerData = LockoutDb[ realmName ][ charNdx ] or {};
    local total_ilevel, equippped_ilevel, pvp_ilevel = GetAverageItemLevel();

    playerData.charName = charName
    playerData.className = className

    playerData.iLevel = {};
    playerData.iLevel[ "total" ]    = total_ilevel;
    playerData.iLevel[ "equipped" ] = equippped_ilevel;
    playerData.iLevel[ "pvp" ]      = pvp_ilevel;
    
    LockoutDb[ realmName ][ charNdx ] = playerData;            -- initialize playerDb if not already initialized

    self:Lockedout_BuildInstanceLockout( realmName, charNdx );
    self:Lockedout_BuildWorldBoss( realmName, charNdx );
    self:Lockedout_BuildCurrencyList( realmName, charNdx );
    self:Lockedout_BuildEmissary( realmName, charNdx );
    self:Lockedout_BuildWeeklyQuests( realmName, charNdx );
    
    table.sort( LockoutDb ); -- sort the realms alphabetically
    
    return realmName, charNdx, playerData;
end -- Lockedout_GetCurrentCharData()
