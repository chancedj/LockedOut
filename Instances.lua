--[[
    This file is to deal with the code to generate the lockout table/vector and
    to handle the refresh of data and deletion of stale data
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next, type, table, select, sfmt, tsort = -- variables
      next, type, table, select,  string.format, table.sort      -- lua functions

-- cache blizzard function/globals
local GetRealmName, GetNumRFDungeons, GetRFDungeonInfo,                                        -- variables
      GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetSavedInstanceInfo,
      GetSavedInstanceEncounterInfo, SendChatMessage, IsInGroup, IsInRaid, IsInInstance,
      C_GetMapTable, C_GetWeeklyBestForMap, C_GetMapUIInfo, EJ_GetInstanceForMap,
      C_GetOwnedKeystoneChallengeMapID, C_GetOwnedKeystoneLevel, GetServerTime,
      C_RequestMapInfo, C_RequestRewards, C_GetBestMapForUnit, EJ_GetInstanceInfo                                          =

      GetRealmName, GetNumRFDungeons, GetRFDungeonInfo,                                        -- blizzard api
      GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetSavedInstanceInfo,
      GetSavedInstanceEncounterInfo, SendChatMessage, IsInGroup, IsInRaid, IsInInstance,
      C_ChallengeMode.GetMapTable, C_MythicPlus.GetWeeklyBestForMap, C_ChallengeMode.GetMapUIInfo, EJ_GetInstanceForMap,
      C_MythicPlus.GetOwnedKeystoneChallengeMapID, C_MythicPlus.GetOwnedKeystoneLevel, GetServerTime,
      C_MythicPlus.RequestMapInfo, C_MythicPlus.RequestRewards, C_Map.GetBestMapForUnit, EJ_GetInstanceInfo

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

    instanceData[ key ] = instanceData[ key ] or {};
    instanceData[ key ][ difficultyName ] = instanceData[ key ][ difficultyName ] or {};
    instanceData[ key ][ difficultyName ].isRaid = false;
    instanceData[ key ][ difficultyName ].resetDate = resetDate;
    instanceData[ key ][ difficultyName ].difficulty = difficulty;

    return instanceData[ key ][ difficultyName ];
end

function addon:removeExpiredInstances()
    local currentTime = GetServerTime() - (60 * 60);

    for realmName, realmData in next, LockoutDb do
        for charNdx, charData in next, realmData do
            local instanceLockData = charData.instanceLockData or {};
            for i = #instanceLockData, 1, -1 do
                local secondsElapsed = currentTime - instanceLockData[ i ].timeSaved;

                if( secondsElapsed > 0) then
                    instanceLockData[ i ] = nil;
                end
            end
        end
    end
end

local function removeUntouchedInstances( instances )
    -- fix up the displayText now, and remove instances with no boss kills.
    for instanceKey, instanceDetails in next, instances do
        local validInstanceFound = false;
        for difficultyName, instance in next, instanceDetails do
            if( difficultyName == addon.KEY_KEYSTONE ) then
                instance.displayText = "+" .. instance.difficulty;
                validInstanceFound = true;
            elseif( difficultyName == addon.KEY_MYTHICBEST ) then
                instance.displayText = "[" .. instance.difficulty .. "]";
                validInstanceFound = true;
            else
                local killCount, totalCount = getBossData( instance.bossData );
                
                if( killCount == 0 ) then
                    -- remove instance from list
                    instances[ instanceKey ][ difficultyName ] = nil;
                else
                    local _, difficultyAbbr = convertDifficulty( instance.difficulty );
                    instance.displayText = killCount .. "/" .. totalCount .. difficultyAbbr;
                    
                    validInstanceFound = true;
                end
            end
        end -- for difficultyName, instance in next, instanceDetails

        if( not validInstanceFound ) then
            instances[ instanceKey ] = nil;
            
            addon:debug( "removing instance: ", instanceKey );
        end -- if( validInstanceCount == 0 )
    end -- for instanceKey, instanceDetails in next, instances
end -- removeUntouchedInstances()

---[[
local connectedRealmsCache = { {} };
function addon:GetConnectedRealms( realmName )
    if ( connectedRealmsCache[ realmName] ) and ( #connectedRealmsCache[ realmName] > 0 ) then
        addon:debug( "pulling from cache" );
        return connectedRealmsCache[ realmName];
    end

    local libRealm = LibStub("LibRealmInfo");
    local realmIdList = select( 9, libRealm:GetRealmInfo( realmName ) );
    local connectedRealms = {}

    for i = 1, #realmIdList do
      local _, connectedName, connectedApiName = libRealm:GetRealmInfoByID( realmIdList[ i ] );
      connectedRealms[ #connectedRealms + 1 ] = connectedName;
    end

    addon:debug( "Instance lock applies to these realms: ", table.concat( connectedRealms, ", ") );

    connectedRealmsCache[ realmName] = connectedRealms;

    return connectedRealmsCache[ realmName ];
end
--]]

local function getPlayerInstanceId()
    local MapId = C_GetBestMapForUnit("player");

    -- if it returns 0 the data is not ready yet.
    if( MapId == 0) then
        return 0, 0;
    end

    local instanceID = EJ_GetInstanceForMap( MapId );
    local _, _, difficulty = GetInstanceInfo();
    return instanceID, difficulty;
end

local instanceNameCache = {};
function addon:GetInstanceName( instanceId )
    local instanceName = instanceNameCache[ instanceId ];

    if( instanceName ) then
        return instanceName;
    end

    instanceNameCache[ instanceId ] = EJ_GetInstanceInfo( instanceId );

    return instanceNameCache[ instanceId ]
end

local function lockedInstanceInList( instanceId, difficulty )
    local found = false;
    local instanceLockData = addon.playerDb.instanceLockData

    for _, lockData in next, instanceLockData do
        if ( lockData.instanceId == instanceId ) and ( lockData.difficulty == difficulty ) and ( not lockData.instanceWasReset ) then
            addon:debug( "found instance: ", addon:GetInstanceName( lockData.instanceId ) );

            return lockData;
        end
    end

    return nil;
end

local function flagInstancesAsReset()
    local instanceLockData = addon.playerDb.instanceLockData;

    for i = 1, #instanceLockData do
        if( not instanceLockData[ i ].instanceWasReset ) then
            addon:debug( "flagged as reset: ", addon:GetInstanceName( instanceLockData[ i ].instanceId ) );
            instanceLockData[ i ].instanceWasReset = true;
        end
    end
end


function addon:getLockDataByChar( realmName, charNdx )
    local charData = LockoutDb[ realmName ][ charNdx ];
    local instanceLockData = charData.instanceLockData or {};

    local charLockData = {};
    for ndx, singleLockData in next, instanceLockData do
        charLockData[ #charLockData + 1 ] = {
            realmName = realmName,
            charName = charData.charName,
            instanceId = singleLockData.instanceId,
            timeSaved = singleLockData.timeSaved
        };
    end

    addon:debug( "Char: ", charNdx, " is locked to ", #charLockData, " instances.");
    return charLockData;
end

function addon:getLockDataByRealm( realmName )
    local connectedRealms = addon:GetConnectedRealms( realmName );

    local realmLockData = {};
    for _, connectedRealmName in next, connectedRealms do
        local realmChars = LockoutDb [ connectedRealmName ];
        if( realmChars ) then
            for charNdx, charData in next, realmChars do
                local tmpLockData = addon:getLockDataByChar( connectedRealmName, charNdx );

                addon:mergeTable( realmLockData, tmpLockData );
            end
        end
    end

    tsort( realmLockData, function( a, b ) return a.timeSaved < b.timeSaved end);

    return realmLockData;
end

function addon:IncrementInstanceLockCount()
    addon:removeExpiredInstances();
    local instanceId, difficulty = getPlayerInstanceId();
    local instanceLockData = addon.playerDb.instanceLockData or {};

    local lockedTotal = #addon:getLockDataByRealm( addon.currentRealm );
    if( lockedTotal > 5 ) then
        print( sfmt(L["You have used %d/10 instance locks this hour."], lockedTotal) );
    end

    if( instanceId > 0 ) then
        local lockedInstance = lockedInstanceInList( instanceId, difficulty );
        if( lockedInstance ) then
            lockedInstance.timeSaved = GetServerTime();
        else
            addon:debug( "adding instance to list: ", addon:GetInstanceName( instanceId ) );
            instanceLockData[ #instanceLockData + 1 ] = {
                                                            instanceId = instanceId,
                                                            difficulty = difficulty,
                                                            timeSaved = GetServerTime(),
                                                            instanceWasReset = false
                                                        };
        end
    end

     addon.playerDb.instanceLockData = instanceLockData;
end

local function callbackResetInstances( test )
    local msg = addonName .. " - " .. L["Instances Reset"];
    local instanceId = getPlayerInstanceId();

    if( instanceId ~= 0 ) then
        print( L["Reset can only be successful outside of the instance."] );
        return;
    end

    -- we maintain a list of instances.  when the reset is called,
    -- flag them as reset so we can keep incrementing the list.
    flagInstancesAsReset();

    if( IsInRaid() ) then
        SendChatMessage( msg, "RAID" );
    elseif( IsInGroup() ) then
        SendChatMessage( msg, "PARTY" );
    else
        print( msg );
    end
end

-- hook in after function is defined
hooksecurefunc("ResetInstances", callbackResetInstances);

function addon:Lockedout_BuildInstanceLockout( )
    local instances = {}; -- initialize instance table;
    
    ---[[
    local lfrCount = GetNumRFDungeons();
    local calculatedResetDate = addon:getWeeklyLockoutDate();

    C_RequestMapInfo();
    --C_RequestRewards();

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

    local keystoneMapId = C_GetOwnedKeystoneChallengeMapID();
    if ( keystoneMapId ) then
        local keystoneMapName = C_GetMapUIInfo( keystoneMapId );
        local keystoneLevel = C_GetOwnedKeystoneLevel();
        
        addon:debug( "info: " .. keystoneMapName .." (" .. keystoneMapId .. ") level: " .. keystoneLevel );
        addKeystoneData( addon.KEY_KEYSTONE, instances, keystoneMapName, keystoneLevel, calculatedResetDate );
    end

    ---[[
    -- this is for getting the best keystone done per map
    for _, mapId in next, C_GetMapTable() do
        --local _, _, bestLevel = C_GetMapPlayerStats( mapId );
        local _, bestLevel = C_GetWeeklyBestForMap( mapId );
        if( bestLevel ) then
            local mapName = C_GetMapUIInfo( mapId );
            addKeystoneData( addon.KEY_MYTHICBEST, instances, mapName, bestLevel, calculatedResetDate );
            addon:debug( mapName, " - bestLevel: ", bestLevel );
        end
    end
    --]]

    removeUntouchedInstances( instances );
    
    addon.playerDb.instances = instances;
end -- Lockedout_BuildInstanceLockout()
