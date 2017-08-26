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

function CheckForMissingMappings()
	-- get current tier setting so we don't step on what's currently set
	local showRaid = true;
	local currentTier = EJ_GetCurrentTier();

	local worldBosses = {}
	
	-- world bosses started with Pandaria - so start with that one and skip the ones before it.
	for tierId = 5, EJ_GetNumTiers() do
		EJ_SelectTier( tierId );
		
		-- the world bosses are under the first instance for all (Pandaria, Draenor, Broken Isles)
		-- so just stick with getting the instance back for the first
		local instanceID, instanceName = EJ_GetInstanceByIndex( 1, showRaid );
		print( "[" .. instanceName .. "]" );
		---[[
		local bossIndex = 1;
		local bossName, _, bossID = EJ_GetEncounterInfoByIndex( bossIndex, instanceID );
		while bossID do
			worldBosses[ bossID ] = {}
			worldBosses[ bossID ].instanceID = instanceID;
			worldBosses[ bossID ].bossName = bossName;

			bossIndex = bossIndex + 1;
			bossName, _, bossID = EJ_GetEncounterInfoByIndex( bossIndex, instanceID );
		end
		--]]
	end

	-- set it back to the current tier
	EJ_SelectTier( currentTier );	
end
		
function Lockedout_BuildWorldBoss( realmName, charNdx, playerData )
	playerData.worldbosses = {}; -- initialize world boss table;
	
	CheckForMissingMappings()
end -- Lockedout_BuildInstanceLockout()
