local _, addonHelpers = ...;

function addonHelpers:fif(condition, if_true, if_false)
  if condition then return if_true; else return if_false; end
end -- function addonHelpers:fif

function addonHelpers:convertDifficulty(difficulty)
	local difficultyName = "unk: " .. difficulty

	if difficulty == 14 then		difficultyName = "normal";
	elseif difficulty == 15 then	difficultyName = "heroic";
	elseif difficulty == 16 then	difficultyName = "mythic";
	elseif difficulty == 17 then	difficultyName = "lfr";
	elseif difficulty == 23 then	difficultyName = "mythic";
	end -- if difficulty

	return difficultyName
end -- function addonHelpers:convertDifficulty

-- recursive printing for debug purposes
function addonHelpers:printTable( tbl, indent )
	if ( tbl == nil ) then return; end;
	
	for key, value in next, tbl do
		if ( type ( value ) == "table" ) then
			print( indent .. key );

			addonHelpers:printTable( value, "  " .. indent );
		elseif( type( value ) == "boolean" ) then
			print( indent .. key .. " - " .. addonHelpers:fif( value, "true", "false" ) );
		else
			print( indent .. key .. " - " .. value );
		end;
	end;
	
end -- function addonHelpers:printTable