--[[
	This file is for overall helper functions that are to be used addon wide.
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- cache lua functions
local print, type =								-- variables
	  print, type								-- lua functions
-- cache blizzard function/globals
local GetCurrentRegion, RAID_CLASS_COLORS =						-- variables
	  GetCurrentRegion, CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS; -- blizzard global table

function addon:fif(condition, if_true, if_false)
  if condition then return if_true; else return if_false; end
end -- addon:fif()

function addon:colorizeString( className, value )
	if( className == nil ) then return value; end

	local sStart, sTail, classColor = "|c", "|r", RAID_CLASS_COLORS[ className ].colorStr;
	
	return sStart .. classColor .. value .. sTail;
end -- addon:colorizeString

function addon:destroyDb()
	if( LockoutDb == nil ) then return; end
	
	local _, charData = next( LockoutDb );
	if( charData == nil ) then LockoutDb = nil; return; end
	
	local key = next( charData );
	-- if the char ndx is not a number, we have the old style so destroy db
	if( type( key ) ~= "number" ) then LockoutDb = nil; end;
end -- destroyDb

-- tues for US, Wed for rest?
local MapRegionReset = {
	[1] = 3, -- US
	[2] = 4, -- KR
	[3] = 4, -- EU
	[4] = 4, -- TW
	[5] = 4  -- CN
}

function addon:getWeeklyLockoutDate()
	local daysInweek, serverResetDay = 7, MapRegionReset[ GetCurrentRegion() ];
	local currentServerTime = GetServerTime();
	local daysLefToReset = (daysInweek + serverResetDay - date( "*t", currentServerTime ).wday) % daysInweek
	-- build next reset date
	local nextResetTime = currentServerTime + GetQuestResetTime();

	local weeklyResetTime = nextResetTime + (daysLefToReset * 24 * 60 * 60);
	-- if we've already exceeded the expected lockout date, bump it a week
	if( currentServerTime > weeklyResetTime ) then
		weeklyResetTime = nextResetTime + (7 * 24 * 60 * 60);
	end
	return weeklyResetTime
end
