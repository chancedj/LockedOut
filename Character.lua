--[[
	This file is to deal with the code to generate the lockout table/vector and
	to handle the refresh of data and deletion of stale data
--]]
local addonName, addonHelpers = ...;

-- libraries
local L = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- cache blizzard function/globals
local GetRealmName, UnitName, UnitClass, GetAverageItemLevel =  -- variables 
	  GetRealmName, UnitName, UnitClass, GetAverageItemLevel;   -- blizzard api

--[[
	this will generate the saved data for characters and realms
	
	the data is stored in this way [key] (prop1, prop2, ...):
	
	[realmName]
		[playerNdx] (charName, className,currIlvl, maxIlvl, instances)
			instances() = [instanceName]
							[difficultyName] (bossData, locked, displayText)
								[bossNdx] (bossName, isKilled)
			worldbosses() = [bossName]
	
--]]

local function getCharIndex( characters, search_charName )
	local charNdx = #characters + 1;

	for searchNdx, character in next, characters do
		if( search_charName == character.charName ) then
			return searchNdx;
		end; -- if( search_charName == character.charName )
	end -- for searchNdx, character in next, characters
	
	return charNdx;
end -- getCharIndex()

local function clearExpiredLockouts( dataTable )
	if( dataTable == ni ) then return; end
	local currentServerTime = GetServerTime();
	
	for key, data in next, dataTable do
		if( data.resetDate == nil ) or ( data.resetDate < currentServerTime ) then
			dataTable[ key ] = nil;
		end -- if( data.resetDate == nil ) or ( data.resetDate < currentServerTime )
	end -- for key, data in next, dataTable
end -- clearExpiredLockouts()

local function allCleared( ... )
	local arg = { ... };

	for i, v in ipairs( arg ) do
		if( v ~= nil ) then
			-- if this returns data, we still have data that's not expired
			local key, data = next(v);
			
			if( data ~= nil ) then
				return false;
			end -- if( data ~= nil )
		end;
	end -- for i, v in ipairs( arg )

	return true;
end -- allCleared( arg, ... )

local function checkExpiredLockouts()
	-- if we add a new element, it will be empty for the charData
	-- take care of this by exiting.
	if( LockoutDb == nil ) then return; end
	
	for realmName, characters in next, LockoutDb do
		for charNdx, charData in next, characters do
			for instanceName, instanceData in next, charData.instances do
				clearExpiredLockouts( instanceData );
				
				-- if the data expired and emptys our table, clear the instance table
				local key = next(instanceData);
				if( key == nil ) then
					charData.instances[ instanceName ] = nil;
				end
			end
			
			clearExpiredLockouts( charData.worldBosses );
			
			local emptySet = allCleared( charData.instances,
										 charData.worldBosses );
			
			if( emptySet ) then characters[ charNdx ] = nil; end
		end -- for charNdx, charData in next, characters
	end -- for realmName, charData in next, LockoutDb
end -- checkExpiredLockouts()

function addonHelpers:Lockedout_GetCurrentCharData()
	addonHelpers:destroyDb();
	checkExpiredLockouts();
	
	-- get and initialize realm data
	local realmName = GetRealmName();
	LockoutDb = LockoutDb or {};							-- initialize database if not already initialized
	LockoutDb[ realmName ] = LockoutDb[ realmName ] or {};	-- initialize realmDb if not already initialized

	-- get and initialize character data
	local charName = UnitName( "player" );
	local _, className = UnitClass( "player" );
	local charNdx = getCharIndex( LockoutDb[ realmName ], charName );
	local playerData = {};

	playerData.charName = charName
	playerData.className = className
	
	LockoutDb[ realmName ][ charNdx ] = playerData;			-- initialize playerDb if not already initialized

	table.sort( LockoutDb ); -- sort the realms alphabetically
	
	return realmName, charName, charNdx;
end -- Lockedout_GetCurrentCharData()
