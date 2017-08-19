--[[
	This file is to deal with the code to generate the lockout table/vector and
	to handle the refresh of data and deletion of stale data
--]]
local _, addonHelpers = ...;

local function convertDifficulty(difficulty)
	if difficulty == 1 then			return "Normal", "N";
	elseif difficulty == 2 then		return "Heroic", "H";
	elseif difficulty == 3 then		return "Normal", "N";
	elseif difficulty == 4 then		return "Normal", "N";
	elseif difficulty == 5 then		return "Heroic", "H";
	elseif difficulty == 6 then		return "Heroic", "H";
	elseif difficulty == 7 then		return "Lfr", "L";
	elseif difficulty == 11 then	return "Heroic", "H";
	elseif difficulty == 12 then	return "Normal", "N";
	elseif difficulty == 14 then	return "Normal", "N";
	elseif difficulty == 15 then	return "Heroic", "H";
	elseif difficulty == 16 then	return "Mythic", "M";
	elseif difficulty == 17 then	return "Lfr", "L";
	elseif difficulty == 23 then	return "Mythic", "M";
	end -- if difficulty

	return "Unknown", "U"
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

--[[
	this will generate the saved data for raids and dungeons for a specific player [and realm].
	
	the data is stored in this way [key] (prop1, prop2, ...):
	
	[realmName]
		[playerName]
			[instanceName]
				[difficultyName] (bossData, locked, displayText)
					[bossNdx] (bossName, isKilled)
	
--]]
function Lockedout_PrintMsg()
	addonHelpers:printTable( LockoutDb );
end -- Lockedout_PrintMsg

function Lockedout_RebuildCharData()
	local maxDungeonId = 2000;

	local playerName = UnitName( "player" );					-- get the name of the current player
	local realmName = GetRealmName();							-- get the name of the current realm
	local playerData = {};
	
	---[[
	local lfrCount = GetNumRFDungeons();
	for lfrNdx = 1, lfrCount do
		local instanceID, name, typeID, subtypeID
			, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel
			, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday
			, bonusRepAmount, minPlayers, isTimeWalker, instanceName, minGearLevel = GetRFDungeonInfo( lfrNdx );

		local numEncounters, _ = GetLFGDungeonNumEncounters( instanceID );
		local bossData = getBossData( instanceID, numEncounters, GetLFGDungeonEncounterInfo );

		addInstanceData( playerData, instanceName, difficulty, bossData, numEncounters, false, false );
	end -- for lfrNdx = 1, lfrCount
	--]]

	---[[
	local lockCount = GetNumSavedInstances();
	for lockId = 1, lockCount do
		local instanceName, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo( lockId );

		-- if reset == 0, it's expired but can be extended - so it will still show in the list.
		if ( reset > 0 ) then
			local bossData = getBossData( lockId, numEncounters, GetSavedInstanceEncounterInfo );

			addInstanceData( playerData, instanceName, difficulty, bossData, numEncounters, locked, isRaid );
		end -- if( reset > 0 )
	end -- for lockId = 1, lockCount
	--]]
	
	LockoutDb = LockoutDb or {};								-- initialize database if not already initialized
	LockoutDb[ realmName ] = LockoutDb[ realmName ] or {};		-- initialize realmDb if not already initialized
	LockoutDb[ realmName ][ playerName ] = playerData;			-- initialize playerDb if not already initialized
	
	table.sort( LockoutDb ); -- sort the realms alphabetically
end -- Lockedout_PrintMsg()
