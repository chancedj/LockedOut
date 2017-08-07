local function fif(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end

function LockHelper_PrintMsg()
	local maxDungeonId = 2000;

	local playerName = UnitName("player");
	local realmName = GetRealmName();
	
	print (playerName .. ' - ' .. realmName);
	
	local t = {};
	
	t[realmName] = {};
	t[realmName][playerName] = '1';
	
	for realmKey, realmTable in pairs(t) do
		print('realm: ' .. realmKey);
		for playerKey, playerTable in pairs( realmTable ) do
			print('=>player: ' .. playerKey .. ' ' .. playerTable);
		end
	end
	
	---[[
	print('just WoD RF Dungeons[begin]');
	local lfrCount = GetNumRFDungeons();
	for lfrId=1,lfrCount do
		local instanceID, name, typeID, subtypeID
			, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel
			, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday
			, bonusRepAmount, minPlayers, isTimeWalker, name2, minGearLevel = GetRFDungeonInfo(lfrId);

		--print('[' .. lfrId .. '|' .. id .. ']name:' .. name2 .. '-' .. name .. ' difficulty: ' .. difficulty);
		local numEncounters, numCompleted = GetLFGDungeonNumEncounters(instanceID);

		for ndx=1, numEncounters do
			local bossName, _, isKilled = GetLFGDungeonEncounterInfo(instanceID, ndx)
			if (isKilled) then
				print('   ' .. bossName .. ' Dead' );
			end
		end
	end -- lfrId=1,lfrCount do
	print('just WoD RF Dungeons[end]');
	--]]

	-- we will use this to build the list.  the the GetNumSavedInstances() and GetNumRFDungeons() calls to populate.
	---[[
	print('Just all WoD Raids [begin]');
	for dungeonId = 1,maxDungeonId do
		-- get back a list of all the dungeon and scenarios.
		-- we want only the raid and dungeons though
		local name, typeID, subtypeID
			, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel
			, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday
			, bonusRepAmount, minPlayers, isTimeWalker, name2, minGearLevel = GetLFGDungeonInfo(dungeonId);
		
		-- make sure the name is not nil/empty and the object is of a type Raid (2)
		-- name2 holds the Proper name for LFR as opposed to the seperate wings
		if not (name == nil or name == "") and typeID == 2 and expansionLevel == 6 then
			local numEncounters, numCompleted = GetLFGDungeonNumEncounters(dungeonId);
			local link = GetSavedInstanceChatLink(dungeonId);

			if (numCompleted > 0) and (link ~= nil) then
				print(link);
			end
		end --if not (name == nil or name == "") then
	end -- for dungeonId = 1,maxDungeonId,1 do
	print('Just all WoD Raids [end]');
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