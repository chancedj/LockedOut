--[[
	This file is for overall helper functions that are to be used addon wide.
--]]
local _, addonHelpers = ...;

function addonHelpers:fif(condition, if_true, if_false)
  if condition then return if_true; else return if_false; end
end -- addonHelpers:fif()

function addonHelpers:colorizeString( className, value )
	if( className == nil ) then return value; end

	local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;
	
	local sStart, sTail, classColor = "|c", "|r", RAID_CLASS_COLORS[ className ].colorStr;
	
	return sStart .. classColor .. value .. sTail;
end -- addonHelpers:colorizeString
