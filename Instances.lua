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

--[[

    -- use this to determine the mapping so we can properly utilize blizzard
    -- to handle localizations
    GetEncounterMapping() => {
        EncounterInfo[ EncounterName ] => {
            EncounterID
            -- boss will be sorted by order they appear in encounter journal
            Bosses => {
                bossID
                bossName
            }
        }
    }

--]]
--local EncounterInfo = nil;
--local EncounterMap = nil;
local function PrepEncounterMapping()
    --[[
    if( EncounterInfo ) then
        return;
    end
    --]]

    -- get current tier setting so we don't step on what's currently set
    local currentTierId = EJ_GetCurrentTier();
    local isRaidTable = { false, true };
    
    EncounterInfo = {};
    EncounterMap = {};
    for tierId = 1, EJ_GetNumTiers() do
        EJ_SelectTier( tierId );
        
        for _, isRaid in next, isRaidTable do
            -- the world bosses are under the first instance for all (Pandaria, Draenor, Broken Isles)
            -- so just stick with getting the instance back for the first
            local encounterIndex = 1;
            local encounterId, encounterName = EJ_GetInstanceByIndex( encounterIndex, isRaid );
            while( encounterId ) do
                if( encounterId ) then
                    EJ_SelectInstance( encounterId );

                    local bossIndex = 1;
                    local bossName, _, bossId = EJ_GetEncounterInfoByIndex( bossIndex );
                    local bosses = {};
                    local bossMap = {};
                    while( bossName ) do
                        bosses[ #bosses + 1 ] = { bossName = bossName, bossId = bossId };
                        bossMap[ bossName ] = { bossId = bossId, bossIndex = #bosses };

                        --if( string.find( bossName, "Corruption" ) ) then
                        --    print( "bossIndex = : ", #bosses, " bossid: ", bossId );
                        --end
                        
                        bossIndex = bossIndex + 1;
                        bossName, _, bossId = EJ_GetEncounterInfoByIndex( bossIndex );
                    end -- while bossName

                    EncounterMap[ encounterName ] = {
                        encounterId = encounterId,
                        bossMap = bossMap;
                    };
                    EncounterInfo[ encounterId ] = {
                        encounterName = encounterName,
                        bosses = bosses
                    }
                    addon:debug( "tier: ", tierId,  " encounterId: ", encounterId, " isRaid: " , isRaid, " encounterName: ", encounterName, " bossCount: ", #bosses );
                end -- if( encounterId ) then

                encounterIndex = encounterIndex + 1;
                encounterId, encounterName = EJ_GetInstanceByIndex( encounterIndex, isRaid );
            end -- while( encounterId ) do
        end -- for _, isRaid in next, isRaidTable do
    end -- for tierId = 1, EJ_GetNumTiers()

    -- set it back to the current tier
    EJ_SelectTier( currentTierId );    

    addon.EncounterInfo = EncounterInfo;
    addon.EncounterMap = EncounterMap;
    
    return;
end -- CheckForMissingMappings()

--[[ This is required because the boss name in the encounter journal
     does not match with the boss in the stupid name that is returned from the API
     so we need to map so we know later to fix the boss names using the correct translation
     though this will have an added side effect of using the boss name from EJ and not the actual
     instance.
--]] 
local bossMap = {
    -- [ EncounterId ] = { [ numEncounters ] = { [ unmappedBossIndex ] = { bossIndex, bossId } } }
    -- Emerald Nightmare
    [ 768 ] = 
    {
        -- encounter (LFR VS other)
        [ 3 ] = 
        {
            -- boss encounter index
            [ 2 ] = { bossIndex = 2, bossId = 1738 }
        },
        [ 11 ] = 
        {
            -- boss encounter index
            [ 5 ] = { bossIndex = 2, bossId = 1738 }
        },
    },
    -- Antorus, the Burning Throne
    [ 946 ] = 
    {
        -- encounter (LFR VS other)
        [ 3 ] = 
        {
            -- boss encounter index
            [ 2 ] = { bossIndex = 5, bossId = 2025 }
        },
        [ 11 ] = 
        {
            -- boss encounter index
            [ 5 ] = { bossIndex = 5, bossId = 2025 }
        },
    }
}

local function populateBossData( bossData, instanceSaveId, numEncounters, fnEncounter, encounterId, encounterBossMap )
    for encounterNdx = 1, numEncounters do
        local bossName, _, isKilled = fnEncounter( instanceSaveId, encounterNdx );

        local mapOverride = nil;
        if( encounterBossMap == nil ) then
            print( "encounterBossMap: is nil ", bossName );
        elseif( encounterBossMap[ bossName ] == nil ) then
            -- need to include a hack. can't use texture for Saved, but can for Lfr
            -- may have to have a specfic place to hook in and map a replacement
            -- get the correct mapping since the names don't match
            mapOverride = bossMap[ encounterId ][ numEncounters ][ encounterNdx ];

            if( mapOverride == nil ) then
                print( bossName, " is missing from map w/ encounter: ", encounterId );
                print( "e: ", encounterId, " encounterNdx: ", encounterNdx, " ne: " , numEncounters );
            end
        end

        local bossMapping = mapOverride or encounterBossMap[ bossName ];
        bossData[ #bossData + 1 ] = {
            bossName = bossName, 
            isKilled = isKilled, 
            bossId =  bossMapping.bossId,
            bossIndex = bossMapping.bossIndex
        };
    end -- for encounterNdx = 1, numEncounters
    
    return bosses;
end -- populateBossData()

local function addInstanceData( instanceData, instanceName, difficulty, numEncounters, locked, isRaid, resetDate )
    local difficultyName, difficultyAbbr = convertDifficulty( difficulty );

    local key = EncounterMap[ instanceName ] and EncounterMap[ instanceName ].encounterId or instanceName;
    
    instanceData[ key ] = instanceData[ key ] or {};
    instanceData[ key ][ difficultyName ] = instanceData[ key ][ difficultyName ] or {};
    instanceData[ key ][ difficultyName ].locked = locked;
    instanceData[ key ][ difficultyName ].isRaid = isRaid;
    instanceData[ key ][ difficultyName ].resetDate = resetDate;
    instanceData[ key ][ difficultyName ].difficulty = difficulty;
    instanceData[ key ][ difficultyName ].encounterId = EncounterMap[ instanceName ].encounterId;
    
    return instanceData[ key ][ difficultyName ];
end -- addInstanceData()

local function removeUntouchedInstances( instances )
    -- fix up the displayText now, and remove instances with no boss kills.
    for instanceKey, instanceDetails in next, instances do
        local validInstanceCount = 0;
        for difficultyName, instance in next, instanceDetails do
            local killCount, totalCount = getBossData( instance.bossData );
            
            if( killCount == 0 ) then
                -- remove instance from list
                instances[ instanceKey ][ difficultyName ] = nil;
            else
                local _, difficultyAbbr = convertDifficulty( instance.difficulty );
                instance.displayText = killCount .. "/" .. totalCount .. difficultyAbbr;
                
                validInstanceCount = validInstanceCount + 1;
            end
        end -- for difficultyName, instance in next, instanceDetails
        
        if( validInstanceCount == 0 ) then
            instances[ instanceKey ] = nil;
        end -- if( validInstanceCount == 0 )
    end -- for instanceKey, instanceDetails in next, instances
end -- removeUntouchedInstances()

function addon:Lockedout_BuildInstanceLockout( realmName, charNdx )
    local instances = {}; -- initialize instance table;
    
    PrepEncounterMapping();
    
    ---[[
    local lfrCount = GetNumRFDungeons();
    local calculatedResetDate = addon:getWeeklyLockoutDate();
    for lfrNdx = 1, lfrCount do
        local instanceID, _, _, _, _, _, _, _, _, _, _, _, difficulty, _, _, _
            , _, _, _, instanceName, _ = GetRFDungeonInfo( lfrNdx );

        local numEncounters = GetLFGDungeonNumEncounters( instanceID );
        
        if( EncounterMap[ instanceName ] == nil ) then
            print( "missing: ", instanceName );
        end
        
        local instanceData = addInstanceData( instances, instanceName, difficulty, numEncounters, false, true, calculatedResetDate );

        instanceData.bossData = instanceData.bossData or {};
        if( _G.LFGLockList and _G.LFGLockList[ tonumber(instanceID) ] == nil ) then
            populateBossData( instanceData.bossData, instanceID, numEncounters, GetLFGDungeonEncounterInfo, EncounterMap[ instanceName ].encounterId, EncounterMap[ instanceName ].bossMap );
        end
    end -- for lfrNdx = 1, lfrCount
    --]]

    ---[[
    local lockCount = GetNumSavedInstances();
    for lockId = 1, lockCount do
        local instanceName, _, reset, difficulty, locked, _, _, isRaid, _, _, numEncounters, _ = GetSavedInstanceInfo( lockId );

        if( EncounterMap[ instanceName ] == nil ) then
            print( instanceName, " not found! ", instanceID );
        end
            
        -- if reset == 0, it's expired but can be extended - so it will still show in the list.
        if ( reset > 0 ) then
            local resetDate = GetServerTime() + reset;
            local instanceData = addInstanceData( instances, instanceName, difficulty, numEncounters, locked, isRaid, resetDate);

            instanceData.bossData = {};
            populateBossData( instanceData.bossData, lockId, numEncounters, GetSavedInstanceEncounterInfo, EncounterMap[ instanceName ].encounterId, EncounterMap[ instanceName ].bossMap );
        end -- if( reset > 0 )
    end -- for lockId = 1, lockCount
    --]]

    -- get mythic+ keystone info
    --[[
    for bagID = 0, NUM_BAG_SLOTS do
        for slotID = 1, GetContainerNumSlots(bagID) do
            local link = GetContainerItemLink( bagID, slotID );
            
            if link and string.find( link, "Keystone: " ) then
                local _, mapID, level = strsplit( ":", link );
                local mapName = C_ChallengeMode.GetMapInfo( mapID );
                print( "keystone found: link: " .. tostring( link ) );
                print( "info: " .. mapName .." (" .. mapID .. ") level: " .. level );
                
                break;
            end
        end
    end
    --]]

    removeUntouchedInstances( instances );
    -- sort the bosses, has to be done after LFR and completed instances are combined and removed.
    for i, instanceData in next, instances do
        for j, instanceDetails in next, instanceData do
            if( instanceData.bosses ) then
                table.sort( instanceData.bosses, function( a, b ) return a.bossIndex < b.bossIndex; end );
            end
        end
    end
    
    LockoutDb[ realmName ][ charNdx ].instances = instances;
end -- Lockedout_BuildInstanceLockout()
