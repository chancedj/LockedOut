--[[
	This file is for overall helper functions that are to be used addon wide.
--]]
local addonName, addonHelpers = ...;
local L = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- cache lua functions
local print, type =								-- variables
	  print, type								-- lua functions
-- cache blizzard function/globals
local RAID_CLASS_COLORS =						-- variables
	  CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS; -- blizzard global table

function addonHelpers:fif(condition, if_true, if_false)
  if condition then return if_true; else return if_false; end
end -- addonHelpers:fif()

function addonHelpers:colorizeString( className, value )
	if( className == nil ) then return value; end

	local sStart, sTail, classColor = "|c", "|r", RAID_CLASS_COLORS[ className ].colorStr;
	
	return sStart .. classColor .. value .. sTail;
end -- addonHelpers:colorizeString

function addonHelpers:destroyDb()
	if( LockoutDb == nil ) then return; end
	
	local _, charData = next( LockoutDb );
	if( charData == nil ) then LockoutDb = nil; return; end
	
	local key = next( charData );
	-- if the char ndx is not a number, we have the old style so destroy db
	if( type( key ) ~= "number" ) then LockoutDb = nil; end;
end -- destroyDb
