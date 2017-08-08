local _, addonHelpers = ...;

local function getDeadBosses( data )
	local deadCount = 0;
	
	for _, data in next, data do
		if ( data.isKilled ) then
			deadCount = deadCount + 1;
		end -- if ( data.isKilled )
	end -- for _, data in next, data
	
	return deadCount;
end -- function getDeadBosses()

--[[
	this will generate the saved data for raids and dungeons for a specific player [and realm].
	
	the data is stored in this way [key] (prop1, prop2, ...):
	
	[realmName]
		[playerName]
			[instanceName]
				[typeName]	(instanceId, numEncounters, lockoutExpiration)
					[bossNdx] (name, isKilled)
	
--]]
function LockHelper_PrintMsg()
	local maxDungeonId = 2000;

	local playerName = UnitName("player");						-- get the name of the current player
	local realmName = GetRealmName();							-- get the name of the current realm
	local playerData = {};
	
	---[[
	local lfrCount = GetNumRFDungeons();
	for lfrNdx = 1, lfrCount do
		local instanceID, name, typeID, subtypeID
			, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel
			, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday
			, bonusRepAmount, minPlayers, isTimeWalker, instanceName, minGearLevel = GetRFDungeonInfo( lfrNdx );

		local bossData = {};
		local numEncounters, _ = GetLFGDungeonNumEncounters( instanceID );

		for encounterNdx = 1, numEncounters do
			local bossName, _, isKilled = GetLFGDungeonEncounterInfo( instanceID, encounterNdx );
			
			bossData[ encounterNdx ] = {};
			bossData[ encounterNdx ].bossName = bossName;
			bossData[ encounterNdx ].isKilled = isKilled;
		end -- for encounterNdx = 1, numEncounters

		-- only save if we've killed a boss
		if getDeadBosses( bossData ) > 0 then
			local difficultyName = addonHelpers:convertDifficulty( difficulty );
			playerData[ instanceName ] = playerData[ instanceName ] or {};
			playerData[ instanceName ][ difficultyName ] = playerData[ instanceName ][ difficultyName ] or {};
			playerData[ instanceName ][ difficultyName ].bossData = bossData;
		end -- if getDeadBosses( bossData ) > 0
	end -- for lfrNdx = 1, lfrCount
	--]]

	---[[
	local lockCount = GetNumSavedInstances();
	for lockId = 1, lockCount do
		local instanceName, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo( lockId );

		local bossData = {};
		for encounterNdx = 1,numEncounters do
			local bossName, _, isKilled, _ = GetSavedInstanceEncounterInfo( lockId, encounterNdx );
			
			bossData[ encounterNdx ] = {};
			bossData[ encounterNdx ].bossName = bossName;
			bossData[ encounterNdx ].isKilled = isKilled;
		end -- for encounterNdx = 1, numEncounters

		-- only save if we've killed a boss
		if getDeadBosses( bossData ) > 0 then
			local difficultyName = addonHelpers:convertDifficulty( difficulty );
			playerData[ instanceName ] = playerData[ instanceName ] or {};
			playerData[ instanceName ][ difficultyName ] = playerData[ instanceName ][ difficultyName ] or {};
			playerData[ instanceName ][ difficultyName ].bossData = bossData;
		end -- if getDeadBosses( bossData ) > 0
	end -- for lockId = 1, lockCount do
	--]]
	
	local LockHelperDb = LockHelperDb or {};						-- initialize variable if not already initialized
	LockHelperDb[ realmName ] = LockHelperDb[ realmName ] or {};	-- initialize realm if not already initialized
	LockHelperDb[ realmName ][ playerName ] = playerData;			-- initialize player if not already initialized
	
	addonHelpers:printTable(LockHelperDb, "=>");

end -- function LockHelper_PrintMsg()