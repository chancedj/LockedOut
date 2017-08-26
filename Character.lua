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

function addonHelpers:Lockedout_GetCurrentCharData()
	addonHelpers:destroyDb();
	
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
