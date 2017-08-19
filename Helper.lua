--[[
	This file is for overall helper functions that are to be used addon wide.
--]]
local _, addonHelpers = ...;

function addonHelpers:fif(condition, if_true, if_false)
  if condition then return if_true; else return if_false; end
end -- addonHelpers:fif()

-- recursive printing for debug purposes
function addonHelpers:printTable( tbl, maxDepth, depth )
	if ( tbl == nil ) then return; end
	if ( maxDepth ~= nil ) and ( depth == maxDepth ) then return; end
	
	depth = depth or 0; -- initialize depth to 0 if nil
	local indent = strrep( "  ", depth ) .. "=>";
	
	for key, value in next, tbl do
		if ( type ( value ) == "table" ) then
			print( indent .. key );

			-- initialize depth to 0 if nil
			addonHelpers:printTable( value, maxDepth, depth + 1 );
		elseif( type( value ) == "boolean" ) then
			print( indent .. key .. " - " .. addonHelpers:fif( value, "true", "false" ) );
		elseif( type( value ) == "function" ) then
			print( indent .. key .. " = " .. value() );
		else
			print( indent .. key .. " - " .. value );
		end -- if ( type ( value ) == "table" )
	end -- for key, value in next, tbl
	
end -- addonHelpers:printTable()

function addonHelpers:colorizeString( className, value )
	if( className == nil ) then return value; end

	local RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;
	
	local sStart, sTail, classColor = "|c", "|r", RAID_CLASS_COLORS[ className ].colorStr;
	
	return sStart .. classColor .. value .. sTail;
end -- addonHelpers:colorizeString
