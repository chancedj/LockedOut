--[[
	This file is for dealing with handling the minimap creation and display
--]]
local addonName, addonHelpers = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local icon = LibStub( "LibDBIcon-1.0" );
local L = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- cache lua functions
local next, table =	-- variables
	  next, table	-- lua functions

local LockedoutMo = LibStub( "LibDataBroker-1.1" ):NewDataObject( "Locked Out", {
	type = "data source",
	text = L[ "Locked Out" ],
	icon = "Interface\\Icons\\Inv_misc_key_10",
	OnClick = function( self ) addonHelpers:OnClick( self ) end,
	OnEnter = function( self ) addonHelpers:OnEnter( self ) end,
} ); -- local LockedoutMo

function addon:OnInitialize()
	LockoutMapDb = LockoutMapDb or LibStub( "AceDB-3.0" ):New( "LockoutMapDb", { profile = { minimap = {hide = false } } } );

	icon:Register(addonName, LockedoutMo, LockoutMapDb.profile.minimap)
end -- addon:OnInitialize

-- Get a reference to the lib
local LibQTip = LibStub( "LibQTip-1.0" )

function addonHelpers:OnClick()
	-- removed, can't rebuild data while tooltip is displaying
	--Lockedout_BuildInstanceLockout();
end -- addonHelpers:OnClick

local function emptyFunction()
end

local function populateInstanceData( header, tooltip, charList, instanceList )
	-- make sure it's not empty
	if ( next( instanceList ) == nil ) then return; end

	-- start adding the instances we have completed with any chacters
	local lineNum = tooltip:AddLine( );
	tooltip.lines[ lineNum ].is_header = true;
	tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );
	for instanceName, _  in next, instanceList do
		lineNum = tooltip:AddLine( instanceName );
		
		for colNdx, charData in next, charList do
			if (LockoutDb[ charData.realmName ] ~= nil) and
			   (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
			   (LockoutDb[ charData.realmName ][ charData.charNdx ].instances[ instanceName ] ~= nil) then
				local data = {};
				local instances = LockoutDb[ charData.realmName ][ charData.charNdx ].instances[ instanceName ];
				local instanceDisplay = {};
				for difficulty, instanceDetails in next, instances do
					data[ #data + 1 ] = instanceDetails.displayText;
				end -- for difficulty, instanceDetails in next, instances

				instanceDisplay.displayTT =	function( data )
												local ttName = "loInTT" .. instanceName;
												local tt = LibQTip:Acquire( "LockedoutTooltip" );
												local tooltip = LibQTip:Acquire( ttName );
												
												local col = 2;
												
												tooltip:SetColumnLayout( 1 );
												tooltip:AddHeader( "Boss Name" );
												for difficulty, instanceData in next, instances do
													local col = tooltip:AddColumn( "CENTER" );

													local ln = 1;
													tooltip:SetCell( ln, col, difficulty, nil, "CENTER" );
													tooltip:SetLineColor( ln, 1, 1, 1, 1 );
													for bossName, bossData in next, instanceData.bossData do
														if( col == 2 ) then
															ln = tooltip:AddLine(  );
														else
															ln = ln + 1;
														end -- if( col == 2 )
													
														local status = "";
														if ( bossData.isKilled ) then
															status = "|cFFFF0000" .. L["Defeated"] .. "|r"; 
														else
															status = "|cFF00FF00" .. L["Available"] .. "|r";
														end; -- if ( bossData.isKilled )

														tooltip:SetCell( ln, 1, bossName, nil, "CENTER" );
														tooltip:SetCell( ln, col, status, nil, "CENTER" );
													end -- for bossName, bossData in next, instanceData.bossData
												end -- for difficulty, instanceDetails in next, instances
												
												tooltip:SmartAnchorTo( tt );
												tooltip:Show();
											end -- function( data )
				instanceDisplay.deleteTT =	function( data )
												local ttName = "loInTT" .. instanceName;
												local tooltip = LibQTip:Acquire( ttName );
												
												LibQTip:Release( tooltip );
											end -- function( data )

				tooltip:SetCell( lineNum, colNdx + 1, addonHelpers:colorizeString( charData.className, table.concat( data, " " ) ), nil, "CENTER" );
				tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", function() instanceDisplay:displayTT( instances ); end );	-- open tooltip with info when entering cell.
				tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", function() instanceDisplay:deleteTT( instances ); end );	-- close out tooltip when leaving
				tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );				-- empty function allows the background to highlight
			end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
		end -- for colNdx, charData in next, charList
	end

	tooltip:AddSeparator( );
end -- populateInstanceData

local function populateWorldBossData( header, tooltip, charList, worldBossList )
	-- make sure it's not empty
	if ( next( worldBossList ) == nil ) then return; end

	-- start adding the instances we have completed with any chacters
	local lineNum = tooltip:AddLine( );
	tooltip.lines[ lineNum ].is_header = true;
	tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );
	for bossName, _ in next, worldBossList do
		lineNum = tooltip:AddLine( bossName );
		
		for colNdx, charData in next, charList do
			if (LockoutDb[ charData.realmName ] ~= nil) and
			   (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
			   (LockoutDb[ charData.realmName ][ charData.charNdx ].worldBosses[ bossName ] ~= nil) then
				local bossData = LockoutDb[ charData.realmName ][ charData.charNdx ].worldBosses[ bossName ];
				
				tooltip:SetCell( lineNum, colNdx + 1, bossData.displayText, nil, "CENTER" );
				tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", emptyFunction );	-- close out tooltip when leaving
				tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", emptyFunction );	-- open tooltip with info when entering cell.
				tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );				-- empty function allows the background to highlight
			end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
		end -- for colNdx, charData in next, charList
	end -- for bossName, _ in next, worldBossList

	tooltip:AddSeparator( );
end -- populateInstanceData

local function populateCurrencyData( header, tooltip, charList, currencyList )
	-- make sure it's not empty
	if ( next( currencyList ) == nil ) then return; end

	-- start adding the instances we have completed with any chacters
	local lineNum = tooltip:AddLine( );
	tooltip.lines[ lineNum ].is_header = true;
	tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );
	for currencyName, _ in next, currencyList do
		lineNum = tooltip:AddLine( currencyName );
		
		for colNdx, charData in next, charList do
			if (LockoutDb[ charData.realmName ] ~= nil) and
			   (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
			   (LockoutDb[ charData.realmName ][ charData.charNdx ].currency[ currencyName ] ~= nil) then
				local currData = LockoutDb[ charData.realmName ][ charData.charNdx ].currency[ currencyName ];
				
				local displayText = currData.displayText;
				if( currData.displayTextAddl ~= nil ) then
					displayText = displayText .. currData.displayTextAddl;
				end
				tooltip:SetCell( lineNum, colNdx + 1, addonHelpers:colorizeString( charData.className, displayText ), nil, "CENTER" );
				tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", emptyFunction );	-- close out tooltip when leaving
				tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", emptyFunction );	-- open tooltip with info when entering cell.
				tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );				-- empty function allows the background to highlight
			end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
		end -- for colNdx, charData in next, charList
	end -- for currencyName, _ in next, currencyList

	tooltip:AddSeparator( );
end -- populateInstanceData

local function addColorBanding( tt )
	local resetnum = 0;
	local opacLevel;
	for i = 1, tt:GetLineCount() do
		opacLevel = 0;
		if( tt.lines[ i ].is_header ) then
			resetnum = i % 2;
			opacLevel = 0.3;
		elseif( ( i + resetnum ) % 2 == 0 ) then
			opacLevel = 0.1;
		end
		tt:SetLineColor( i, 1, 1, 1, opacLevel );
	end -- for i = 1, tt:GetLineCount()
end -- addColorBanding

function addonHelpers:OnEnter( self )
	if ( self.tooltip ~= nil ) then
		LibQTip:Release( self.tooltip );
		self.tooltip = nil;
	end -- if ( self.tooltip ~= nil )

	local realmName, _, charNdx = addonHelpers:Lockedout_GetCurrentCharData();
	local playerData = LockoutDb[ realmName ][ charNdx ];

	Lockedout_BuildInstanceLockout( realmName, charNdx, playerData );
	Lockedout_BuildWorldBoss( realmName, charNdx, playerData );
	Lockedout_BuildCurrentList( realmName, charNdx, playerData );

	-- Acquire a tooltip with 3 columns, respectively aligned to left, center and right
	local tooltip = LibQTip:Acquire( "LockedoutTooltip" );
	self.tooltip = tooltip;

	local realmCount = 0;
	local charList = {};
	local dungeonList = {};
	local raidList = {};
	local worldBossList = {};
	local currencyList = {};

	-- get list of characters and realms for the horizontal
	for realmName, characters in next, LockoutDb do
		realmCount = realmCount + 1;
		for charNdx, charData in next, characters do
			local tblNdx = #charList + 1;
			charList[ tblNdx ] = {}
			charList[ tblNdx ].charNdx = charNdx;
			charList[ tblNdx ].realmName = realmName;
			charList[ tblNdx ].charName = charData.charName;
			charList[ tblNdx ].className = charData.className;

			-- the get a list of all instances across characters for vertical
			for instanceName, details in next, charData.instances do
				local key, data = next( details );
				
				if ( data.isRaid ) then
					raidList[ instanceName ] = "set";
				else
					dungeonList[ instanceName ] = "set";
				end -- if ( data.isRaid )
			end -- for instanceName, _ in next, instances
			
			charData.worldBosses = charData.worldBosses or {};
			for bossName, _ in next, charData.worldBosses do
				worldBossList[ bossName ] = "set"
			end -- for bossName, _ in next, charData.worldBosses
			
			charData.currency = charData.currency or {};
			for currName, _ in next, charData.currency do
				currencyList[ currName ] = "set"
			end -- for currName, _ in next, charData.currency
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
	table.sort( worldBossList );
	table.sort( currencyList );
	
	-- initialize the column count going forward
	tooltip:SetColumnLayout( #charList + 1 );

	-- Add a header filling only the first columns in the first 2 rows (Realm, Character)
	local realmLineNum;
	local charLineNum;
	
	if( realmCount > 1 ) then -- show realm only when multiple are involved
		realmLineNum = tooltip:AddHeader( L[ "Realm" ] ); -- realm column
	end
	charLineNum  = tooltip:AddHeader( L[ "Character" ] ); -- char column
	-- add the characters and realms across the header
	for colNdx, char in next, charList do
		if( realmCount > 1 ) then -- show realm only when multiple are involved
			tooltip:SetCell( realmLineNum, colNdx + 1, addonHelpers:colorizeString( char.className, char.realmName ), nil, "CENTER" );
		end
		local charData = LockoutDb[ char.realmName ][ char.charNdx ];
		local charDisplay = {};
		charDisplay.displayTT =	function( data )
									if ( charData.iLevel == nil ) then
										return;
									end

									local ttName = "loChTT" .. charData.charName;
									local tt = LibQTip:Acquire( "LockedoutTooltip" );
									local tooltip = LibQTip:Acquire( ttName );
									tooltip:SetColumnLayout( 2 );
									local line = tooltip:AddHeader( "" );
									tooltip:SetLineColor( line, 1, 1, 1, 1 );
									tooltip:SetCell( line, 1, L["Character iLevels"], 2 );
									for k, p in next, charData.iLevel do
										tooltip:AddLine( k, p );
									end -- for k, p in next, charData.iLevel

									tooltip:SmartAnchorTo( tt );
									tooltip:Show();
								end -- function( data )
		charDisplay.deleteTT =	function( data )
									local ttName = "loChTT" .. charData.charName;
									local tooltip = LibQTip:Acquire( ttName );
									
									LibQTip:Release( tooltip );
								end -- function( data )

		tooltip:SetCell( charLineNum, colNdx + 1, addonHelpers:colorizeString( char.className, char.charName ), nil, "CENTER" );
		tooltip:SetCellScript( charLineNum, colNdx + 1, "OnEnter", function() charDisplay:displayTT( charData ); end ); -- close out tooltip when leaving
		tooltip:SetCellScript( charLineNum, colNdx + 1, "OnLeave", function() charDisplay:deleteTT( charData ); end );	 -- close out tooltip when leaving
	end -- for colNdx, char in next, charList

	tooltip:AddSeparator( );
	tooltip:AddSeparator( );

	populateInstanceData( L[ "Dungeon" ], tooltip, charList, dungeonList );
	populateInstanceData( L[ "Raid" ], tooltip, charList, raidList );
	populateWorldBossData( L["World Boss"], tooltip, charList, worldBossList );
	populateCurrencyData( L["Currency"], tooltip, charList, currencyList );

	-- Use smart anchoring code to anchor the tooltip to our frame
	tooltip:SmartAnchorTo( self );
	tooltip:SetAutoHideDelay( 0.25, self );

	addColorBanding( tooltip );
	
	-- Show it, et voilà !
	tooltip:Show();
end --  addonHelpers:OnEnter

function addonHelpers:OnLeave( self )
	-- Release the tooltip
	--LibQTip:Release( self.tooltip );
	--self.tooltip = nil;
end -- addonHelpers:OnLeave
