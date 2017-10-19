--[[
    This file handles world boss information.
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next = -- variables
      next   -- lua functions

-- cache blizzard function/globals
local EJ_GetCurrentTier, EJ_SelectTier, EJ_GetInstanceByIndex, EJ_GetEncounterInfoByIndex, IsQuestFlaggedCompleted,
        READY_CHECK_READY_TEXTURE, IsQuestActive =          -- variables 
      EJ_GetCurrentTier, EJ_SelectTier, EJ_GetInstanceByIndex, EJ_GetEncounterInfoByIndex, IsQuestFlaggedCompleted,
        READY_CHECK_READY_TEXTURE, C_TaskQuest.IsActive     -- blizzard api

-- Blizzard api cannot link npc id's to world quests, so we have to hardcode
local WORLD_BOSS_LIST = {
    -- Pandaria
    [691]  = { instanceId=322, questId=32099, bossName="Sha of Anger", },
    [725]  = { instanceId=322, questId=32098, bossName="Salyis's Warband" },
    [814]  = { instanceId=322, questId=32518, bossName="Nalak, The Storm Lord", },
    [826]  = { instanceId=322, questId=32519, bossName="Oondasta",  },
    [857]  = { instanceId=322, questId=33117, bossName="Celestials" }, -- bossName="Chi-Ji, The Red Crane", }, remapped name
    [858]  = { instanceId=322, questId=0,     bossName="Yu'lon, The Jade Serpent", }, -- mapped so i don't chase missing mappings
    [859]  = { instanceId=322, questId=0,     bossName="Niuzao, The Black Ox", }, -- mapped so i don't chase missing mappings
    [860]  = { instanceId=322, questId=0,     bossName="Xuen, The White Tiger", }, -- mapped so i don't chase missing mappings
    [861]  = { instanceId=322, questId=33118, bossName="Ordos, Fire-God of the Yaungol", },
    
    -- Draenor
    [1211] = { instanceId=557, questId=37462, bossName="Tarlna the Ageless" },
    [1262] = { instanceId=557, questId=37464, bossName="Rukhmar" },
    [1291] = { instanceId=557, questId=37462, bossName="Drov the Ruiner" },
    [1452] = { instanceId=557, questId=39380, bossName="Supreme Lord Kazzak" },

    -- Broken Isles
    [1749] = { instanceId=822, questId=42270, bossName="Nithogg" },
    [1756] = { instanceId=822, questId=42269, bossName="The Soultakers" },
    [1763] = { instanceId=822, questId=42779, bossName="Shar'thos" },
    [1769] = { instanceId=822, questId=43192, bossName="Levantus" },
    [1770] = { instanceId=822, questId=42819, bossName="Humongris" },
    [1774] = { instanceId=822, questId=43193, bossName="Calamir" },
    [1783] = { instanceId=822, questId=43513, bossName="Na'zak the Fiend" },
    [1789] = { instanceId=822, questId=43448, bossName="Drugon the Frostblood" },
    [1790] = { instanceId=822, questId=43512, bossName="Ana-Mouz" },
    [1795] = { instanceId=822, questId=43985, bossName="Flotsam" },
    [1796] = { instanceId=822, questId=44287, bossName="Withered J'im" },
    [1883] = { instanceId=822, questId=46947, bossName="Brutallus" },
    [1884] = { instanceId=822, questId=46948, bossName="Malificus" },
    [1885] = { instanceId=822, questId=46945, bossName="Si'vash" },
    [1956] = { instanceId=822, questId=47061, bossName="Apocron" },

    -- Argus
    [2010] = { instanceId=959, questId=49169, bossName="Matron Folnuna" },
    [2011] = { instanceId=959, questId=49167, bossName="Mistress Alluradel" },
    [2012] = { instanceId=959, questId=49166, bossName="Inquisitor Meto" },
    [2013] = { instanceId=959, questId=49170, bossName="Occularus" },
    [2014] = { instanceId=959, questId=49171, bossName="Sotanathor" },
    [2015] = { instanceId=959, questId=49168, bossName="Pit Lord Vilemus" }
}

function CheckForMissingMappings()
    -- get current tier setting so we don't step on what's currently set
    local showRaid = true;
    local currentTierId = EJ_GetCurrentTier();

    local worldBosses = {};
    
    -- world bosses started with Pandaria - so start with that one and skip the ones before it.
    for tierId = 5, EJ_GetNumTiers() do
        EJ_SelectTier( tierId );
        
        -- the world bosses are under the first instance for all (Pandaria, Draenor, Broken Isles)
        -- so just stick with getting the instance back for the first
        local instanceId, instanceName = EJ_GetInstanceByIndex( 1, showRaid );
        EJ_SelectInstance( instanceId );

        local bossIndex = 1;
        local bossName, _, bossID = EJ_GetEncounterInfoByIndex( bossIndex );
        while bossId do
            worldBosses[ bossId ] = {}
            worldBosses[ bossId ].instanceId = instanceId;
            worldBosses[ bossId ].bossName = bossName;

            bossIndex = bossIndex + 1;
            bossName, _, bossID = EJ_GetEncounterInfoByIndex( bossIndex );
        end -- while bossId
    end -- for tierId = 5, EJ_GetNumTiers()

    -- set it back to the current tier
    EJ_SelectTier( currentTierId );    

    local found = false;
    for bossId, bossData in next, worldBosses do
        if( WORLD_BOSS_LIST[ bossId ] == nil ) then
            print( 'unmapped boss found: [' .. bossId .. '] = { instanceId=' .. bossData.instanceId .. ', questId=0, bossName="' .. bossData.bossName .. '" }' );
            found = true;
        end -- if( WORLD_BOSS_LIST[ bossId ] == nil )
    end; -- for bossId, bossData in next, worldBosses
    
    if( not found ) then
        print( "no mappping issues found" );
    end -- if( not found )
end -- CheckForMissingMappings()

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";
function addon:Lockedout_BuildWorldBoss( realmName, charNdx )
    local worldBosses = {}; -- initialize world boss table;
    
    local calculatedResetDate = addon:getWeeklyLockoutDate();
    for bossId, bossData in next, WORLD_BOSS_LIST do
        if( bossData.questId ) then
            if ( IsQuestFlaggedCompleted( bossData.questId ) ) then
                worldBosses[ bossData.bossName ] = {}
                worldBosses[ bossData.bossName ].displayText = BOSS_KILL_TEXT;
                worldBosses[ bossData.bossName ].resetDate = calculatedResetDate;
            elseif( IsQuestActive( bossData.questId ) ) and ( not addon.config.profile.worldBoss.showKilledOnly ) then -- add option later on to show unkilled bosses
                worldBosses[ bossData.bossName ] = {}
                worldBosses[ bossData.bossName ].displayText = " ";
                worldBosses[ bossData.bossName ].resetDate = calculatedResetDate;
            end -- if ( IsQuestFlaggedCompleted( bossData.questId ) )
        end -- if( bossData.questId )
    end -- for bossId, bossData in next, WORLD_BOSS_LIST
    
    LockoutDb[ realmName ][ charNdx ].worldBosses = worldBosses;
end -- Lockedout_BuildInstanceLockout()
