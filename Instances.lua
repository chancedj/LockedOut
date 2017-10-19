--[[
    This file is to deal with the code to generate the lockout table/vector and
    to handle the refresh of data and deletion of stale data
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next, type, table = -- variables
      next, type, table      -- lua functions

-- cache blizzard function/globals
local GetRealmName, UnitName, UnitClass, GetNumRFDungeons, GetRFDungeonInfo,                                        -- variables
      GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetSavedInstanceInfo, GetSavedInstanceEncounterInfo = -- variables 
      GetRealmName, UnitName, UnitClass, GetNumRFDungeons, GetRFDungeonInfo,                                        -- blizzard api
      GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetSavedInstanceInfo, GetSavedInstanceEncounterInfo   -- blizzard api

local function convertDifficulty(difficulty)
    if difficulty == 1 then         return L[ "Normal" ],   L[ "N" ];
    elseif difficulty == 2 then     return L[ "Heroic" ],   L[ "H" ];
    elseif difficulty == 3 then     return L[ "Normal" ],   L[ "N" ];
    elseif difficulty == 4 then     return L[ "Normal" ],   L[ "N" ];
    elseif difficulty == 5 then     return L[ "Heroic" ],   L[ "H" ];
    elseif difficulty == 6 then     return L[ "Heroic" ],   L[ "H" ];
    elseif difficulty == 7 then     return L[ "Lfr" ],      L[ "L" ];
    elseif difficulty == 11 then    return L[ "Heroic" ],   L[ "H" ];
    elseif difficulty == 12 then    return L[ "Normal" ],   L[ "N" ];
    elseif difficulty == 14 then    return L[ "Normal" ],   L[ "N" ];
    elseif difficulty == 15 then    return L[ "Heroic" ],   L[ "H" ];
    elseif difficulty == 16 then    return L[ "Mythic" ],   L[ "M" ];
    elseif difficulty == 17 then    return L[ "Lfr" ],      L[ "L" ];
    elseif difficulty == 23 then    return L[ "Mythic" ],   L[ "M" ];
    end -- if difficulty

    return L[ "Unknown" ], L[ "U" ]
end -- convertDifficulty

local function getBossData( data )
    local deadCount, totalCount = 0, 0;
    
    for _, boss in next, data do
        totalCount = totalCount + 1;
        if ( boss.isKilled ) then
            deadCount = deadCount + 1;
        end -- if ( data.isKilled )
    end -- for _, data in next, data
    
    return deadCount, totalCount;
end -- getBossData()

local function populateBossData( bossData, encounterId, numEncounters, fnEncounter  )
    for encounterNdx = 1, numEncounters do
        local bossName, _, isKilled = fnEncounter( encounterId, encounterNdx );
    
        bossData[ bossName ] = {};
        bossData[ bossName ].bossName = bossName;
        bossData[ bossName ].isKilled = isKilled;
    end -- for encounterNdx = 1, numEncounters
    
    return bosses;
end -- populateBossData()

local function addInstanceData( instanceData, instanceName, difficulty, numEncounters, locked, isRaid, resetDate )
    local difficultyName, difficultyAbbr = convertDifficulty( difficulty );
    instanceData[ instanceName ] = instanceData[ instanceName ] or {};
    instanceData[ instanceName ][ difficultyName ] = instanceData[ instanceName ][ difficultyName ] or {};
    instanceData[ instanceName ][ difficultyName ].locked = locked;
    instanceData[ instanceName ][ difficultyName ].isRaid = isRaid;
    instanceData[ instanceName ][ difficultyName ].resetDate = resetDate;
    instanceData[ instanceName ][ difficultyName ].difficulty = difficulty;
    
    return instanceData[ instanceName ][ difficultyName ];
end -- addInstanceData()

local function removeUntouchedInstances( instances )
    -- fix up the displayText now, and remove instances with no boss kills.
    for instanceName, instanceDetails in next, instances do
        local validInstanceCount = 0;
        for difficultyName, instance in next, instanceDetails do
            local killCount, totalCount = getBossData( instance.bossData );
            
            if( killCount == 0 ) then
                -- remove instance from list
                instances[ instanceName ][ difficultyName ] = nil;
            else
                local _, difficultyAbbr = convertDifficulty( instance.difficulty );
                instance.displayText = killCount .. "/" .. totalCount .. difficultyAbbr;
                
                validInstanceCount = validInstanceCount + 1;
            end
        end -- for difficultyName, instance in next, instanceDetails
        
        if( validInstanceCount == 0 ) then
            instances[ instanceName ] = nil;
        end -- if( validInstanceCount == 0 )
    end -- for instanceName, instanceDetails in next, instances
end -- removeUntouchedInstances()

function addon:Lockedout_BuildInstanceLockout( realmName, charNdx )
    local instances = {}; -- initialize instance table;
    
    ---[[
    local lfrCount = GetNumRFDungeons();
    local calculatedResetDate = addon:getWeeklyLockoutDate();
    for lfrNdx = 1, lfrCount do
        local instanceID, _, _, _, _, _, _, _, _, _, _, _, difficulty, _, _, _
            , _, _, _, instanceName, _ = GetRFDungeonInfo( lfrNdx );

        local numEncounters = GetLFGDungeonNumEncounters( instanceID );
        local instanceData = addInstanceData( instances, instanceName, difficulty, numEncounters, false, true, calculatedResetDate );

        instanceData.bossData = instanceData.bossData or {};
        populateBossData( instanceData.bossData, instanceID, numEncounters, GetLFGDungeonEncounterInfo );
    end -- for lfrNdx = 1, lfrCount
    --]]

    ---[[
    local lockCount = GetNumSavedInstances();
    for lockId = 1, lockCount do
        local instanceName, _, reset, difficulty, locked, _, _, isRaid, _, _, numEncounters, _ = GetSavedInstanceInfo( lockId );

        -- if reset == 0, it's expired but can be extended - so it will still show in the list.
        if ( reset > 0 ) then
            local resetDate = GetServerTime() + reset;
            local instanceData = addInstanceData( instances, instanceName, difficulty, numEncounters, locked, isRaid, resetDate);

            instanceData.bossData = instanceData.bossData or {};
            populateBossData( instanceData.bossData, lockId, numEncounters, GetSavedInstanceEncounterInfo );
        end -- if( reset > 0 )
    end -- for lockId = 1, lockCount
    --]]
    
    removeUntouchedInstances( instances );
    LockoutDb[ realmName ][ charNdx ].instances = instances;
end -- Lockedout_BuildInstanceLockout()
