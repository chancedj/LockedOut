local _, addonHelpers = ...;

--[[
local function fif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

local function convertDifficulty(difficulty)
	local difficultyName = "unk: " .. difficulty

	if difficulty == 14 then		difficultyName = "normal";
	elseif difficulty == 15 then	difficultyName = "heroic";
	elseif difficulty == 16 then	difficultyName = "mythic";
	elseif difficulty == 17 then	difficultyName = "lfr";
	elseif difficulty == 23 then	difficultyName = "mythic";
	end

	return difficultyName
end

-- recursive printing for debug purposes
local function printTable( tbl, indent )
	if ( tbl == nil ) then return; end;
	
	for key, value in next, tbl do
		if ( type ( value ) == "table" ) then
			print( indent .. key );

			printTable( value, "  " .. indent );
		elseif( type( value ) == "boolean" ) then
			print( indent .. key .. " - " .. fif( value, "true", "false" ) );
		else
			print( indent .. key .. " - " .. value );
		end;
	end;
	
end
--]]
local function getDeadBosses( data )
	local deadCount = 0;
	
	for _, data in next, data do
		if ( data.isKilled ) then
			deadCount = deadCount + 1;
		end;
	end
	
	return deadCount;
end

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
	print('just WoD RF Dungeons[begin]');
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
		end

		-- only save if we've killed a boss
		if getDeadBosses( bossData ) > 0 then
			local difficultyName = addonHelpers:convertDifficulty( difficulty );
			playerData[ instanceName ] = playerData[ instanceName ] or {};
			playerData[ instanceName ][ difficultyName ] = playerData[ instanceName ][ difficultyName ] or {};
			playerData[ instanceName ][ difficultyName ].bossData = bossData;
		end
	end -- lfrId=1,lfrCount do
	print('just WoD RF Dungeons[end]');
	--]]

	---[[
	print('show saved instances[begin]');
	local lockCount = GetNumSavedInstances();
	for lockId = 1, lockCount do
		local instanceName, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo( lockId );

		local bossData = {};
		for encounterNdx = 1,numEncounters do
			local bossName, _, isKilled, _ = GetSavedInstanceEncounterInfo( lockId, encounterNdx );
			
			bossData[ encounterNdx ] = {};
			bossData[ encounterNdx ].bossName = bossName;
			bossData[ encounterNdx ].isKilled = isKilled;
		end

		-- only save if we've killed a boss
		if getDeadBosses( bossData ) > 0 then
			local difficultyName = addonHelpers:convertDifficulty( difficulty );
			playerData[ instanceName ] = playerData[ instanceName ] or {};
			playerData[ instanceName ][ difficultyName ] = playerData[ instanceName ][ difficultyName ] or {};
			playerData[ instanceName ][ difficultyName ].bossData = bossData;
		end
	end -- for lockId=1, lockCount do
	print('show saved instances[end]');
	--]]
	print('done');
	
	local t = t or {};											-- initialize variable if not already initialized
	
	t[ realmName ] = t[ realmName ] or {};							-- initialize realm if not already initialized
	t[ realmName ][ playerName ] = playerData;	-- initialize player if not already initialized
	
	addonHelpers:printTable(t, "=>");

end -- end PrintMsg

LockHelper_PrintMsg();

--