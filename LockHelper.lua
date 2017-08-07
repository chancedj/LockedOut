local function fif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

local function convertDifficulty(difficulty)
	local difficultyName = "unknown"

	if difficulty == 14 then		difficultyName = "normal";
	elseif difficulty == 15 then	difficultyName = "heroic";
	elseif difficulty == 16 then	difficultyName = "mythic";
	elseif difficulty == 17 then	difficultyName = "lfr";
	end

	return difficultyName
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

	local t = t or {};											-- initialize variable if not already initialized
	
	t[realmName] = t[realmName] or {};							-- initialize realm if not already initialized
	t[realmName][playerName] = t[realmName][playerName] or {};	-- initialize player if not already initialized

	---[[
	print('just WoD RF Dungeons[begin]');
	local lfrCount = GetNumRFDungeons();
	for lfrId=1,lfrCount do
		local instanceID, name, typeID, subtypeID
			, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel
			, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday
			, bonusRepAmount, minPlayers, isTimeWalker, name2, minGearLevel = GetRFDungeonInfo(lfrId);

		t[realmName][playerName][name2] = t[realmName][playerName][name2] or {};
		
		local numEncounters, _ = GetLFGDungeonNumEncounters(instanceID);

		for ndx=1, numEncounters do
			local bossName, _, isKilled = GetLFGDungeonEncounterInfo(instanceID, ndx)
			if (isKilled) then
				print('   ' .. bossName .. ' Dead' );
			end
		end
	end -- lfrId=1,lfrCount do
	print('just WoD RF Dungeons[end]');
	--]]

	---[[
	print('show saved instances[begin]');
	local lockCount = GetNumSavedInstances();
	print('lockCount: ' .. lockCount);
	for lockId=1, lockCount do
		local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(lockId);

		print(name .. ' - ' .. difficultyName);
		
		for bossNdx=1,numEncounters do
			local bossName, _, isKilled, _ = GetSavedInstanceEncounterInfo( lockId, bossNdx );
			print('   ' .. bossName .. fif( isKilled, ' Dead', ' Alive'));
		end
	end -- for lockId=1, lockCount do
	print('show saved instances[end]');
	--]]
	print('done');
end -- end PrintMsg

LockHelper_PrintMsg();

--