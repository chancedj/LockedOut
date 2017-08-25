--[[
	This file is to deal with the code to generate the lockout table/vector and
	to handle the refresh of data and deletion of stale data
--]]
local addonName, addonHelpers = ...;

-- libraries
local L = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next, type, table = -- variables
	  next, type, table	  -- lua functions

-- cache blizzard function/globals
local GetRealmName, UnitName, UnitClass, GetNumRFDungeons, GetRFDungeonInfo,										-- variables
	  GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetSavedInstanceInfo, GetSavedInstanceEncounterInfo = -- variables 
	  GetRealmName, UnitName, UnitClass, GetNumRFDungeons, GetRFDungeonInfo,										-- blizzard api
	  GetLFGDungeonNumEncounters, GetLFGDungeonEncounterInfo, GetSavedInstanceInfo, GetSavedInstanceEncounterInfo   -- blizzard api

local function convertDifficulty(difficulty)
	if difficulty == 1 then			return L[ "Normal" ], L[ "N" ];
	elseif difficulty == 2 then		return L[ "Heroic" ], L[ "H" ];
	elseif difficulty == 3 then		return L[ "Normal" ], L[ "N" ];
	elseif difficulty == 4 then		return L[ "Normal" ], L[ "N" ];
	elseif difficulty == 5 then		return L[ "Heroic" ], L[ "H" ];
	elseif difficulty == 6 then		return L[ "Heroic" ], L[ "H" ];
	elseif difficulty == 7 then		return L[ "Lfr" ], L[ "L" ];
	elseif difficulty == 11 then	return L[ "Heroic" ], L[ "H" ];
	elseif difficulty == 12 then	return L[ "Normal" ], L[ "N" ];
	elseif difficulty == 14 then	return L[ "Normal" ], L[ "N" ];
	elseif difficulty == 15 then	return L[ "Heroic" ], L[ "H" ];
	elseif difficulty == 16 then	return L[ "Mythic" ], L[ "M" ];
	elseif difficulty == 17 then	return L[ "Lfr" ], L[ "L" ];
	elseif difficulty == 23 then	return L[ "Mythic" ], L[ "M" ];
	end -- if difficulty

	return L[ "Unknown" ], L[ "U" ]
end -- convertDifficulty

local function getDeadBosses( data )
	local deadCount = 0;
	
	for _, boss in next, data do
		if ( boss.isKilled ) then
			deadCount = deadCount + 1;
		end -- if ( data.isKilled )
	end -- for _, data in next, data
	
	return deadCount;
end -- getDeadBosses()

local function getBossData( encounterId, numEncounters, fnEncounter  )
	local bosses = {};
	
	for encounterNdx = 1, numEncounters do
		local bossName, _, isKilled = fnEncounter( encounterId, encounterNdx );
	
		bosses [ encounterNdx ] = {};
		bosses [ encounterNdx ].bossName = bossName;
		bosses [ encounterNdx ].isKilled = isKilled;
	end -- for encounterNdx = 1, numEncounters
	
	return bosses;
end -- getBossData()

local function addInstanceData( playerData, instanceName, difficulty, bossData, numEncounters, locked, isRaid )
	local deadBosses = getDeadBosses( bossData );
	if ( deadBosses > 0 ) then
		local difficultyName, difficultyAbbr = convertDifficulty( difficulty );
		playerData[ instanceName ] = playerData[ instanceName ] or {};
		playerData[ instanceName ][ difficultyName ] = playerData[ instanceName ][ difficultyName ] or {};
		playerData[ instanceName ][ difficultyName ].bossData = bossData;
		playerData[ instanceName ][ difficultyName ].locked = locked;
		playerData[ instanceName ][ difficultyName ].isRaid = isRaid;
		playerData[ instanceName ][ difficultyName ].displayText = deadBosses .. "/" .. numEncounters .. difficultyAbbr;
	end -- if ( deadBosses > 0 )
end -- addInstanceData()

function Lockedout_BuildInstanceLockout()
	addonHelpers:destroyDb();

	local realmName, charNdx, playerData;
	realmName, _, charNdx = addonHelpers:Lockedout_GetCurrentCharData();
	playerData = LockoutDb[ realmName ][ charNdx ];
	playerData.instances = {}; -- initialize instance table;
	
	---[[
	local lfrCount = GetNumRFDungeons();
	for lfrNdx = 1, lfrCount do
		local instanceID, _, _, _, _, _, _, _, _, _, _, _, difficulty, _, _, _
			, _, _, _, instanceName, _ = GetRFDungeonInfo( lfrNdx );

		local numEncounters = GetLFGDungeonNumEncounters( instanceID );
		local bossData = getBossData( instanceID, numEncounters, GetLFGDungeonEncounterInfo );

		addInstanceData( playerData.instances, instanceName, difficulty, bossData, numEncounters, false, true );
	end -- for lfrNdx = 1, lfrCount
	--]]

	---[[
	local lockCount = GetNumSavedInstances();
	for lockId = 1, lockCount do
		local instanceName, _, reset, difficulty, locked, _, _, isRaid, _, _, numEncounters, _ = GetSavedInstanceInfo( lockId );

		-- if reset == 0, it's expired but can be extended - so it will still show in the list.
		if ( reset > 0 ) then
			local bossData = getBossData( lockId, numEncounters, GetSavedInstanceEncounterInfo );

			addInstanceData( playerData.instances, instanceName, difficulty, bossData, numEncounters, locked, isRaid );
		end -- if( reset > 0 )
	end -- for lockId = 1, lockCount
	--]]
	
end -- Lockedout_BuildInstanceLockout()
