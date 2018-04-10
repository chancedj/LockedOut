--[[
    This file is to deal with the code to generate the lockout table/vector and
    to handle the refresh of data and deletion of stale data
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next, type, table, tsort = -- variables
      next, type, table, table.sort      -- lua functions

-- cache blizzard function/globals
local GetRealmName, UnitName, UnitClass, GetNumRFDungeons, GetRFDungeonInfo,                                        -- variables
      GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetSavedInstanceInfo,
      GetSavedInstanceEncounterInfo,
      C_GetMapTable, C_GetMapPlayerStats, C_GetMapInfo                                          =
      GetRealmName, UnitName, UnitClass, GetNumRFDungeons, GetRFDungeonInfo,                                        -- blizzard api
      GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetSavedInstanceInfo,
      GetSavedInstanceEncounterInfo,
      C_ChallengeMode.GetMapTable, C_ChallengeMode.GetMapPlayerStats, C_ChallengeMode.GetMapInfo

local function convertDifficulty(difficulty)
    if difficulty == 1 then         return L[ "Normal" ],       L[ "N" ];
    elseif difficulty == 2 then     return L[ "Heroic" ],       L[ "H" ];
    elseif difficulty == 3 then     return L[ "Normal" ],       L[ "N" ];
    elseif difficulty == 4 then     return L[ "Normal" ],       L[ "N" ];
    elseif difficulty == 5 then     return L[ "Heroic" ],       L[ "H" ];
    elseif difficulty == 6 then     return L[ "Heroic" ],       L[ "H" ];
    elseif difficulty == 7 then     return L[ "Lfr" ],          L[ "L" ];
    elseif difficulty == 9 then     return L[ "Normal" ],       L[ "N" ];
    elseif difficulty == 11 then    return L[ "Heroic" ],       L[ "H" ];
    elseif difficulty == 12 then    return L[ "Normal" ],       L[ "N" ];
    elseif difficulty == 14 then    return L[ "Normal" ],       L[ "N" ];
    elseif difficulty == 15 then    return L[ "Heroic" ],       L[ "H" ];
    elseif difficulty == 16 then    return L[ "Mythic" ],       L[ "M" ];
    elseif difficulty == 17 then    return L[ "Lfr" ],          L[ "L" ];
    elseif difficulty == 23 then    return L[ "Mythic" ],       L[ "M" ];
    elseif difficulty == 33 then    return L[ "Timewalking" ],  L[ "T" ];
    end -- if difficulty

    print( "unknown difficulty: ", difficulty );
    
    return L[ "Unknown" ], L[ "U" ];
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

local function populateBossData( bossData, instanceSaveId, numEncounters, difficulty, fnEncounter )
    for encounterNdx = 1, numEncounters do
        local bossName, _, isKilled = fnEncounter( instanceSaveId, encounterNdx );

        bossData[ #bossData + 1 ] = {
            bossName = bossName, 
            isKilled = isKilled
        };
    end -- for encounterNdx = 1, numEncounters
    
    return bosses;
end -- populateBossData()

local function addInstanceData( instanceData, instanceName, difficulty, numEncounters, locked, isRaid, resetDate )
    local difficultyName, difficultyAbbr = convertDifficulty( difficulty );

    local key = instanceName;
    
    instanceData[ key ] = instanceData[ key ] or {};
    instanceData[ key ][ difficultyName ] = instanceData[ key ][ difficultyName ] or {};
    instanceData[ key ][ difficultyName ].locked = locked;
    instanceData[ key ][ difficultyName ].isRaid = isRaid;
    instanceData[ key ][ difficultyName ].resetDate = resetDate;
    instanceData[ key ][ difficultyName ].difficulty = difficulty;
    
    return instanceData[ key ][ difficultyName ];
end -- addInstanceData()

local function addKeystoneData( difficultyName, instanceData, instanceName, difficulty, resetDate )
    local key = instanceName;
    --local difficultyName = "keystone";

    instanceData[ key ] = instanceData[ key ] or {};
    instanceData[ key ][ difficultyName ] = instanceData[ key ][ difficultyName ] or {};
    instanceData[ key ][ difficultyName ].isRaid = false;
    instanceData[ key ][ difficultyName ].resetDate = resetDate;
    instanceData[ key ][ difficultyName ].difficulty = difficulty;
    
    return instanceData[ key ][ difficultyName ];
end

local function removeUntouchedInstances( instances )
    -- fix up the displayText now, and remove instances with no boss kills.
    for instanceKey, instanceDetails in next, instances do
        local validInstanceCount = 0;
        for difficultyName, instance in next, instanceDetails do
            if( difficultyName == "keystone" ) then
                instance.displayText = "+" .. instance.difficulty;
                validInstanceCount = 1;
            elseif( difficultyName == "mythicbest" ) then
                instance.displayText = "[" .. instance.difficulty .. "]";
                validInstanceCount = 1;
            else
                local killCount, totalCount = getBossData( instance.bossData );
                
                if( killCount == 0 ) then
                    -- remove instance from list
                    instances[ instanceKey ][ difficultyName ] = nil;
                else
                    local _, difficultyAbbr = convertDifficulty( instance.difficulty );
                    instance.displayText = killCount .. "/" .. totalCount .. difficultyAbbr;
                    
                    validInstanceCount = validInstanceCount + 1;
                end
            end
        end -- for difficultyName, instance in next, instanceDetails
        
        if( validInstanceCount == 0 ) then
            instances[ instanceKey ] = nil;
        end -- if( validInstanceCount == 0 )
    end -- for instanceKey, instanceDetails in next, instances
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
        if( _G.LFGLockList and _G.LFGLockList[ tonumber(instanceID) ] == nil ) then
            populateBossData( instanceData.bossData, instanceID, numEncounters, difficulty, GetLFGDungeonEncounterInfo );
        end
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

            instanceData.bossData = {};
            populateBossData( instanceData.bossData, lockId, numEncounters, difficulty, GetSavedInstanceEncounterInfo );
        end -- if( reset > 0 )
    end -- for lockId = 1, lockCount
    --]]

    -- get mythic+ keystone info
    local keyFound = false;
    for bagID = 0, NUM_BAG_SLOTS do
        for slotID = 1, GetContainerNumSlots(bagID) do
            local link = GetContainerItemLink( bagID, slotID );
            
            if link and string.find( link, "Keystone: " ) then
                local _, mapID, level = strsplit( ":", link );
                local mapName = C_GetMapInfo( mapID );
                addon:debug( "keystone found: link: " .. tostring( link ) );
                addon:debug( "info: " .. mapName .." (" .. mapID .. ") level: " .. level );
                
                addKeystoneData( "keystone", instances, mapName, level, calculatedResetDate );

                -- mark it found, then break out;
                keyFound = true;
                break;
            end
        end
        
        -- since it's a nested loop, we need to break twice.
        if (keyfound) then break end;
    end

    ---[[
    -- this is for getting the best keystone done per map
    for _, mapId in next, C_GetMapTable() do
        local _, _, bestLevel = C_GetMapPlayerStats( mapId );
        if( bestLevel ) then
            local mapName = C_GetMapInfo( mapId );

            addKeystoneData( "mythicbest", instances, mapName, bestLevel, calculatedResetDate );

            addon:debug( mapName, " - bestLevel: ", bestLevel );
        end
    end
    --]]
    
    removeUntouchedInstances( instances );
    
    LockoutDb[ realmName ][ charNdx ].instances = instances;
end -- Lockedout_BuildInstanceLockout()
