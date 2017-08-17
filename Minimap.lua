--[[
	This file is for dealing with handling the minimap creation and display
--]]
local addonName, addonHelpers = ...;

local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0");
local icon = LibStub("LibDBIcon-1.0");
local LockHelperMo = LibStub("LibDataBroker-1.1"):NewDataObject("Lock Helper", {
	type = "data source",
	text = "Lock Helper",
	icon = "Interface\\Icons\\Inv_misc_key_10",
	OnClick = function( self ) addon:OnClick( self ) end,
	OnEnter = function( self ) addon:OnEnter( self ) end,
	OnLeave = function( self ) addon:OnLeave( self ) end,
}); -- local LockHelperMo

function addon:OnInitialize()
	LockHelperMapDb = LockHelperMapDb or LibStub("AceDB-3.0"):New("LockHelperMapDb", { profile = { minimap = {hide = false } } });

	icon:Register(addonName, LockHelperMo, LockHelperMapDb.profile.minimap)
end -- addon:OnInitialize

-- Get a reference to the lib
local LibQTip = LibStub('LibQTip-1.0')

function addon:OnClick()
	LockHelper_RebuildCharData();
	LockHelper_PrintMsg();
end -- addon:OnClick

function addon:OnEnter( self )
	LockHelper_RebuildCharData();
	-- Acquire a tooltip with 3 columns, respectively aligned to left, center and right
	local tooltip = LibQTip:Acquire("LockHelperTooltip");
	self.tooltip = tooltip;

	local charList = {};
	local instanceList = {};

	-- this needs to be corrected later for different realms with same char names
	for realmName, characters in next, LockHelperDb do
		for charName, instances in next, characters do
			local tblNdx = #charList + 1;
			charList[ tblNdx ] = {}
			charList[ tblNdx ].realmName = realmName;
			charList[ tblNdx ].charName = charName;
			for instanceName, _ in next, instances do
				if instanceList[ instanceName ] == nil then
					instanceList[ instanceName ] = "set";
				end -- if instanceList[ instanceName ] == nil
			end -- for instanceName, _ in next, instances
		end -- for charName, instances in next, characters
	end -- for realmName, characters in next, LockHelperDb
	
	-- sort list by realm then character
	table.sort( charList, function(l, r)
							if (l.realmName ~= r.realmName) then
								return l.realmName < r.realmName;
							end
							
							return l.charName < r.charName;
						  end
	);
	-- sort instance list
	table.sort( instanceList );
	
	-- Add an header filling only the first two columns
	tooltip:SetColumnLayout( #charList + 1 );
	local realmLineNum, _ = tooltip:AddHeader( "Realm" ); -- realm column
	local charLineNum, _ = tooltip:AddHeader( "Character" ); -- char column
	-- add the characters and realms across the header
	for colNdx, char in next, charList do
		tooltip:SetCell( realmLineNum, colNdx + 1, char.realmName, nil, "CENTER" );
		tooltip:SetCell( charLineNum, colNdx + 1, char.charName, nil, "CENTER" );
	end -- for colNdx, char in next, charList

	tooltip:AddSeparator( );
	-- start adding the instances we have completed with any chacters
	for instanceName, _  in next, instanceList do
		local lineNum = tooltip:AddLine( instanceName );
		
		for colNdx, charData in next, charList do
			if (LockHelperDb[ charData.realmName ] ~= nil) and
			   (LockHelperDb[ charData.realmName ][ charData.charName ] ~= nil) and
			   (LockHelperDb[ charData.realmName ][ charData.charName ][ instanceName ] ~= nil) then

				local data = {};
				for difficulty, instanceDetails in next, LockHelperDb[ charData.realmName ][ charData.charName ][ instanceName ] do
					data[ #data + 1 ] = instanceDetails.displayText;
				end -- for difficulty, instanceDetails in next, LockHelperDb[ charData.realmName ][ charData.charName ][ instanceName ]
				
				tooltip:SetCell( lineNum, colNdx + 1, table.concat( data, " " ), nil, "CENTER" );
			end -- if (LockHelperDb[ charData.realmName ] ~= nil) and .....
		end -- for colNdx, charData in next, charList
	end

	-- Use smart anchoring code to anchor the tooltip to our frame
	tooltip:SmartAnchorTo(self);

	-- Show it, et voilà !
	tooltip:Show();
end --  addon:OnEnter

function addon:OnLeave( self )
   -- Release the tooltip
   LibQTip:Release( self.tooltip );
   self.tooltip = nil;
end -- addon:OnLeave
