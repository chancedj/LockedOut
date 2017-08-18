--[[
	This file is for dealing with handling the minimap creation and display
--]]
local addonName, addonHelpers = ...;

local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");
local icon = LibStub("LibDBIcon-1.0");
local LockedoutMo = LibStub("LibDataBroker-1.1"):NewDataObject("Locked Out", {
	type = "data source",
	text = "Locked Out",
	icon = "Interface\\Icons\\Inv_misc_key_10",
	OnClick = function( self ) addon:OnClick( self ) end,
	OnEnter = function( self ) addon:OnEnter( self ) end,
}); -- local LockedoutMo

function addon:OnInitialize()
	LockoutMapDb = LockoutMapDb or LibStub("AceDB-3.0"):New("LockoutMapDb", { profile = { minimap = {hide = false } } });

	icon:Register(addonName, LockedoutMo, LockoutMapDb.profile.minimap)
end -- addon:OnInitialize

-- Get a reference to the lib
local LibQTip = LibStub('LibQTip-1.0')

function addon:OnClick()
	Lockedout_RebuildCharData();
	Lockedout_PrintMsg();
end -- addon:OnClick

local function populateInstanceData( header, tooltip, charList, instanceList )
	-- make sure it's not empty
	if ( next( instanceList ) == nil ) then return; end

	-- start adding the instances we have completed with any chacters
	local lineNum = tooltip:AddLine( );
	tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );
	for instanceName, _  in next, instanceList do
		lineNum = tooltip:AddLine( instanceName );
		
		for colNdx, charData in next, charList do
			if (LockoutDb[ charData.realmName ] ~= nil) and
			   (LockoutDb[ charData.realmName ][ charData.charName ] ~= nil) and
			   (LockoutDb[ charData.realmName ][ charData.charName ][ instanceName ] ~= nil) then

				local data = {};
				for difficulty, instanceDetails in next, LockoutDb[ charData.realmName ][ charData.charName ][ instanceName ] do
					data[ #data + 1 ] = instanceDetails.displayText;
				end -- for difficulty, instanceDetails in next, LockoutDb[ charData.realmName ][ charData.charName ][ instanceName ]
				
				tooltip:SetCell( lineNum, colNdx + 1, table.concat( data, " " ), nil, "CENTER" );
				tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", function() return; end );	-- open tooltip with info when entering cell.
				tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", function() return; end );	-- close out tooltip when leaving
				tooltip:SetLineScript( lineNum, "OnEnter", function() return; end );				-- empty function allows the background to highlight
			end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
		end -- for colNdx, charData in next, charList
	end

	tooltip:AddSeparator( );
end -- populateInstanceData

function addon:OnEnter( self )
	if ( self.tooltip ~= nil ) then
		LibQTip:Release( self.tooltip );
		self.tooltip = nil;
	end

	Lockedout_RebuildCharData();
	-- Acquire a tooltip with 3 columns, respectively aligned to left, center and right
	local tooltip = LibQTip:Acquire("LockedoutTooltip");
	self.tooltip = tooltip;

	local charList = {};
	local dungeonList = {};
	local raidList = {};

	-- get list of characters and realms for the horizontal
	for realmName, characters in next, LockoutDb do
		for charName, instances in next, characters do
			local tblNdx = #charList + 1;
			charList[ tblNdx ] = {}
			charList[ tblNdx ].realmName = realmName;
			charList[ tblNdx ].charName = charName;

			-- the get a list of all instances across characters for vertical
			for instanceName, details in next, instances do
				local key, data = next( details );
				
				if (data.isRaid) then
					raidList[ instanceName ] = "set";
				else
					dungeonList[ instanceName ] = "set";
				end
			end -- for instanceName, _ in next, instances
		end -- for charName, instances in next, characters
	end -- for realmName, characters in next, LockoutDb
	
	-- sort list by realm then character
	table.sort( charList, function(l, r)
							if (l.realmName ~= r.realmName) then
								return l.realmName < r.realmName;
							end
							
							return l.charName < r.charName;
						  end
	);
	-- sort instance list
	table.sort( dungeonList );
	table.sort( raidList );
	
	-- initialize the column count going forward
	tooltip:SetColumnLayout( #charList + 1 );

	-- Add a header filling only the first columns in the first 2 rows (Realm, Character)
	local realmLineNum = tooltip:AddHeader( "Realm" ); -- realm column
	local charLineNum  = tooltip:AddHeader( "Character" ); -- char column
	-- add the characters and realms across the header
	for colNdx, char in next, charList do
		tooltip:SetCell( realmLineNum, colNdx + 1, char.realmName, nil, "CENTER" );
		tooltip:SetCell( charLineNum, colNdx + 1, char.charName, nil, "CENTER" );
	end -- for colNdx, char in next, charList

	tooltip:AddSeparator( );
	tooltip:AddSeparator( );

	populateInstanceData( "Dungeon", tooltip, charList, dungeonList );
	populateInstanceData( "Raid", tooltip, charList, raidList );
	
	-- Use smart anchoring code to anchor the tooltip to our frame
	tooltip:SmartAnchorTo( self );
	tooltip:SetAutoHideDelay( 0.25, self );

	-- Show it, et voilà !
	tooltip:Show();
end --  addon:OnEnter

function addon:OnLeave( self )
	-- Release the tooltip
	--LibQTip:Release( self.tooltip );
	--self.tooltip = nil;
end -- addon:OnLeave
