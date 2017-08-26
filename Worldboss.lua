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
local GetNumSavedWorldBosses, GetSavedWorldBossInfo =	-- variables 
		GetNumSavedWorldBosses, GetSavedWorldBossInfo	-- blizzard api

function Lockedout_BuildWorldBoss( realmName, charNdx, playerData )
	playerData.worldbosses = {}; -- initialize world boss table;
	
	---[[
	for index = 1, GetNumSavedWorldBosses() do
		print( GetSavedWorldBossInfo( index ) );
	end -- for index = 1, GetNumSavedWorldBosses()
	--]]

end -- Lockedout_BuildInstanceLockout()
