--[[
    This file is for dealing with handling the minimap creation and display
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- cache lua functions
local next, table, SecondsToTime, tsort =       -- variables
      next, table, SecondsToTime, table.sort    -- lua functions

-- Get a reference to the lib
local LibQTip = LibStub( "LibQTip-1.0" )

local function addMainColorBanding( tt )
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
end -- addMainColorBanding

local function addPopupColorBanding( tt )
    local opacLevel = 1;
    tt:SetBackdropColor( 0, 0, 0, opacLevel );
    for i = 1, tt:GetLineCount() do
        tt:SetLineColor( i, 0, 0, 0, opacLevel );
    end -- for i = 1, tt:GetLineCount()
end -- addPopupColorBanding

local function getAnchorPkt( groupName, suffix, data, lineNum, cellNum )
    local pkt = {
        groupName = groupName,
        suffix = suffix,
        data = data,
        lineNum = lineNum,
        cellNum = cellNum,
        getTTName = function( self )
                        return "loTT" .. self.groupName .. self.suffix;
                    end
    };
    
    return pkt;
end

local function emptyFunction()
end

local function displayReset( self )
    local ttName = self.anchor:getTTName();
    local tt = LibQTip:Acquire( "LockedoutTooltip" );
    local tooltip = LibQTip:Acquire( ttName );
    
    tooltip:SetColumnLayout( 2 );
    local ln = tooltip:AddLine( );
    tooltip:SetCell( ln, 1, "|cFF00FF00" .. L["*Resets in"] .. "|r", nil, "CENTER" );
    tooltip:SetCell( ln, 2, "|cFFFF0000" .. SecondsToTime( self.anchor.data.resetDate - GetServerTime() ) .. "|r", nil, "CENTER" );
    
    tooltip:SmartAnchorTo( tt.lines[ self.anchor.lineNum ].cells[ self.anchor.cellNum ] );
    addPopupColorBanding( tooltip );
    tooltip:Show();
end -- function( data )

local function closeTT( self )
    local ttName = self.anchor:getTTName();
    local tt = LibQTip:Acquire( ttName );

    LibQTip:Release( tt );
end -- function( data )

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

                instanceDisplay.displayTT = function( self )
                                                local ttName = self.anchor:getTTName();
                                                local tt = LibQTip:Acquire( "LockedoutTooltip" );
                                                local tooltip = LibQTip:Acquire( ttName );
                                                
                                                local col = 2;
                                                
                                                tooltip:SetColumnLayout( 1 );
                                                tooltip:AddHeader( "Boss Name" );
                                                for difficulty, instanceData in next, self.anchor.data do
                                                    local col = tooltip:AddColumn( "CENTER" );

                                                    local ln = 1;
                                                    tooltip:SetCell( ln, col, difficulty, nil, "CENTER" );
                                                    tooltip:SetLineColor( ln, 1, 1, 1, 1 );
                                                    
                                                    if( col == 2 ) then
                                                        ln = tooltip:AddLine( );
                                                    else
                                                        ln = ln + 1;
                                                    end

                                                    tooltip:SetCell( ln, 1, "|cFF00FF00" .. L["*Resets in"] .. "|r", nil, "CENTER" );
                                                    tooltip:SetCell( ln, col, "|cFFFF0000" .. SecondsToTime( instanceData.resetDate - GetServerTime() ) .. "|r", nil, "CENTER" );
                                                    for bossName, bossData in next, instanceData.bossData do
                                                        if( col == 2 ) then
                                                            ln = tooltip:AddLine( );
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
                                                
                                                tooltip:SmartAnchorTo( tt.lines[ self.anchor.lineNum ].cells[ self.anchor.cellNum ] );
                                                addPopupColorBanding( tooltip );
                                                tooltip:Show();
                                            end -- function( data )
                instanceDisplay.deleteTT = closeTT;
                instanceDisplay.anchor = getAnchorPkt( "in", instanceName, instances, lineNum, colNdx + 1 );

                tooltip:SetCell( lineNum, colNdx + 1, addon:colorizeString( charData.className, table.concat( data, " " ) ), nil, "CENTER" );

                tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", function() instanceDisplay:displayTT( ); end );    -- open tooltip with info when entering cell.
                tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", function() instanceDisplay:deleteTT( ); end );    -- close out tooltip when leaving
                tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
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

                local bossDisplay = {};
                bossDisplay.displayTT  = displayReset;
                bossDisplay.deleteTT   = closeTT;
                bossDisplay.anchor     = getAnchorPkt( "wb", bossName, bossData, lineNum, colNdx + 1 );

                tooltip:SetCell( lineNum, colNdx + 1, bossData.displayText, nil, "CENTER" );

                tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", function() bossDisplay:displayTT( ); end );    -- close out tooltip when leaving
                tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", function() bossDisplay:deleteTT( ); end );    -- open tooltip with info when entering cell.
                tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
            end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
        end -- for colNdx, charData in next, charList
    end -- for bossName, _ in next, worldBossList

    tooltip:AddSeparator( );
end -- populateInstanceData

local function populateWeeklyQuestData( header, tooltip, charList, weeklyQuestList )
    -- make sure it's not empty
    if ( next( weeklyQuestList ) == nil ) then return; end

    -- start adding the instances we have completed with any chacters
    local lineNum = tooltip:AddLine( );
    tooltip.lines[ lineNum ].is_header = true;
    tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );

    for questAbbr, questName in next, weeklyQuestList do
        lineNum = tooltip:AddLine( questName );

        for colNdx, charData in next, charList do
            if (LockoutDb[ charData.realmName ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ].weeklyQuests[ questAbbr ] ~= nil) then
                local questData = LockoutDb[ charData.realmName ][ charData.charNdx ].weeklyQuests[ questAbbr ];
                
                local questDisplay = {};
                if( questData.resetDate ~= nil ) then
                    questDisplay.anchor = getAnchorPkt( "ql", questAbbr, questData, lineNum, colNdx + 1 );
                    questDisplay.displayTT = displayReset;
                    questDisplay.deleteTT  = closeTT;
                else
                    -- display nothing if no resetdate is found.
                    questDisplay.anchor = {};
                    questDisplay.displayTT = emptyFunction;
                    questDisplay.deleteTT = emptyFunction;
                end
                
                tooltip:SetCell( lineNum, colNdx + 1, questData.displayText, nil, "CENTER" );

                tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", function() questDisplay:displayTT( ); end );    -- close out tooltip when leaving
                tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", function() questDisplay:deleteTT( ); end );    -- open tooltip with info when entering cell.
                tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
            end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
        end -- for colNdx, charData in next, charList
    end -- for questName, _ in next, weeklyQuestList

    tooltip:AddSeparator( );
end -- populateInstanceData

local function populateCurrencyData( header, tooltip, charList, currencyList )
    -- make sure it's not empty
    if ( next( currencyList ) == nil ) then return; end

    -- start adding the instances we have completed with any chacters
    local lineNum = tooltip:AddLine( );
    tooltip.lines[ lineNum ].is_header = true;
    tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );
    for _, currencyData in next, currencyList do
        local displayName = currencyData.name .. " (" .. addon.ExpansionAbbr[ currencyData.expansionLevel ] .. ")";
        if( currencyData.icon ) then
            lineNum = tooltip:AddLine( currencyData.icon .. displayName );
        end
       
        ---[[
        for colNdx, charData in next, charList do
            if (LockoutDb[ charData.realmName ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ].currency[ currencyData.currencyID ] ~= nil) then
                local currData = LockoutDb[ charData.realmName ][ charData.charNdx ].currency[ currencyData.currencyID ];

                local displayText = "";
                if( currData.count ~= nil ) then
                    displayText = addon:shortenAmount( currData.count );
                    if( currData.maximum > 0 ) then
                        displayText = displayText .. "/" .. addon:shortenAmount( currData.maximum );

                        if( currData.count == currData.maximum ) then
                            displayText = "|cFFFF0000" .. displayText .. "|r";
                        else
                            displayText = "|cFF00FF00" .. displayText .. "|r";
                        end
                    end
                    
                    if( currData.bonus ~= nil ) then
                        displayText = displayText .. "(" .. table.concat( currData.bonus, "/" ) .. ")";
                    end
                end
                tooltip:SetCell( lineNum, colNdx + 1, displayText, nil, "CENTER" );
                tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", emptyFunction );    -- close out tooltip when leaving
                tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", emptyFunction );    -- open tooltip with info when entering cell.
                tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
            end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
        end -- for colNdx, charData in next, charList
        --]]
    end -- for currencyName, _ in next, currencyList

    tooltip:AddSeparator( );
end -- populateInstanceData

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";
local function populateEmissaryData( header, tooltip, charList, emissaryList )
    -- make sure it's not empty
    if ( next( emissaryList ) == nil ) then return; end

    -- start adding the instances we have completed with any chacters
    local lineNum = tooltip:AddLine( );
    tooltip.lines[ lineNum ].is_header = true;
    tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );
    for _, emissaryData in next, emissaryList do
        lineNum = tooltip:AddLine( emissaryData.displayName );
        
        for colNdx, charData in next, charList do
            if( emissaryData.questID ~= nil ) then
                if (LockoutDb[ charData.realmName ] ~= nil) and
                   (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
                   (LockoutDb[ charData.realmName ][ charData.charNdx ].emissaries[ emissaryData.questID ] ~= nil) then
                    local emData = LockoutDb[ charData.realmName ][ charData.charNdx ].emissaries[ emissaryData.questID ];
                    local displayText;
                    if( emData.isComplete ) then
                        displayText = BOSS_KILL_TEXT
                    else
                        displayText = emData.fullfilled .. "/" .. emData.required;
                    end

                    tooltip:SetCell( lineNum, colNdx + 1, displayText, nil, "CENTER" );
                end
            end
            tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
        end -- for colNdx, charData in next, charList
    end -- for currencyName, _ in next, currencyList

    tooltip:AddSeparator( );
end

function addon:ShowInfo( frame )
    if ( self.tooltip ~= nil ) then
        LibQTip:Release( self.tooltip );
        self.tooltip = nil;
    end -- if ( self.tooltip ~= nil )

    local currRealmName, currCharNdx, playerData = addon:Lockedout_GetCurrentCharData();

    -- Acquire a tooltip with 3 columns, respectively aligned to left, center and right
    local tooltip = LibQTip:Acquire( "LockedoutTooltip" );
    self.tooltip = tooltip;

    local realmCount = 0;
    local charList = {};
    local dungeonList = {};
    local raidList = {};
    local worldBossList = {};
    local currencyList = {};
    local emissaryList = { {}, {}, {} }; -- initialize with 3
    local weeklyQuestList = {};

    local CURRENCY_LIST = addon:getCurrencyList();
    local CURRENCY_LIST_MAP = addon:getCurrencyListMap();
    
    -- get list of characters and realms for the horizontal
    for realmName, characters in next, LockoutDb do
        if( not self.config.profile.general.currentRealm ) or ( currRealmName == realmName ) then
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
                
                for bossName, _ in next, charData.worldBosses do
                    worldBossList[ bossName ] = "set"
                end -- for bossName, _ in next, charData.worldBosses
                
                for currID, currData in next, charData.currency do
                    local currNdx = CURRENCY_LIST_MAP[ currID ];
                    local curr = CURRENCY_LIST[ currNdx ];
                    
                    if( curr ~= nil ) and ( self.config.profile.currency.displayList[ currID ] ) then
                        currencyList[ currID ] = currNdx;
                    end
                end -- for currName, _ in next, charData.currency
                
                for questAbbr, questData in next, charData.weeklyQuests do
                    weeklyQuestList[ questAbbr ] = questData.name;
                end
                
                ---[[
                for questID, emData in next, charData.emissaries do
                    if( emData.name ~= nil ) then
                        emissaryList[ emData.day + 1 ] = {
                            displayName = "(+" .. emData.day .. " Day) " .. emData.name,
                            name = emData.name,
                            questID = questID
                        }
                    end
                end
                --]]
            end -- for charName, instances in next, characters
        end
    end -- for realmName, characters in next, LockoutDb
    
    -- sort list by realm then character
    tsort( charList, function(l, r)
                            if (l.realmName ~= r.realmName) then
                                return l.realmName < r.realmName;
                            end
                            
                            return l.charName < r.charName;
                          end
    );

    local currencyDisplayList = {};
    
    for currID, currNdx in next, currencyList do
        currencyDisplayList[ #currencyDisplayList + 1 ] = CURRENCY_LIST[ currNdx ];
    end
    
    -- sort instance list
    tsort( dungeonList );
    tsort( raidList );
    tsort( worldBossList );
    local so = addon:getCurrencyOptions();
    tsort( currencyDisplayList, so[ self.config.profile.currency.sortBy ].sortFunction );
    
    -- initialize the column count going forward
    tooltip:SetColumnLayout( #charList + 1 );

    -- Add a header filling only the first columns in the first 2 rows (Realm, Character)
    local realmLineNum;
    local charLineNum;
    
    if( realmCount > 1 ) and ( self.config.profile.general.showRealmHeader ) then -- show realm only when multiple are involved
        realmLineNum = tooltip:AddHeader( L[ "Realm" ] ); -- realm column
    end
    charLineNum  = tooltip:AddHeader( L[ "Character" ] ); -- char column
    -- add the characters and realms across the header
    for colNdx, char in next, charList do
        if( realmCount > 1 ) and ( self.config.profile.general.showRealmHeader ) then -- show realm only when multiple are involved
            tooltip:SetCell( realmLineNum, colNdx + 1, addon:colorizeString( char.className, char.realmName ), nil, "CENTER" );
        end
        local charData = LockoutDb[ char.realmName ][ char.charNdx ];
        local charDisplay = {};
        charDisplay.displayTT = function( self )
                                    if ( charData.iLevel == nil ) then
                                        return;
                                    end

                                    local ttName = self.anchor:getTTName();
                                    local tt = LibQTip:Acquire( "LockedoutTooltip" );
                                    local tooltip = LibQTip:Acquire( ttName );
                                    tooltip:SetColumnLayout( 2 );
                                    local line = tooltip:AddHeader( "" );
                                    tooltip:SetLineColor( line, 1, 1, 1, 1 );
                                    tooltip:SetCell( line, 1, L["Character iLevels"], 2 );
                                    for k, p in next, self.anchor.data.iLevel do
                                        tooltip:AddLine( k, p );
                                    end -- for k, p in next, charData.iLevel

                                    tooltip:SmartAnchorTo( tt.lines[ self.anchor.lineNum ].cells[ self.anchor.cellNum ] );
                                    addPopupColorBanding( tooltip );
                                    tooltip:Show();
                                end -- function( data )
        charDisplay.deleteTT = closeTT;
        charDisplay.anchor = getAnchorPkt( "ch", charData.charName, charData, charLineNum, colNdx + 1 );

        tooltip:SetCell( charLineNum, colNdx + 1, addon:colorizeString( char.className, char.charName ), nil, "CENTER" );

        tooltip:SetCellScript( charLineNum, colNdx + 1, "OnEnter", function() charDisplay:displayTT( ); end ); -- close out tooltip when leaving
        tooltip:SetCellScript( charLineNum, colNdx + 1, "OnLeave", function() charDisplay:deleteTT( ); end );     -- close out tooltip when leaving
    end -- for colNdx, char in next, charList

    tooltip:AddSeparator( );
    tooltip:AddSeparator( );

    if( self.config.profile.dungeon.show ) then
        populateInstanceData( L[ "Dungeon" ], tooltip, charList, dungeonList );
    end
    if( self.config.profile.raid.show ) then
        populateInstanceData( L[ "Raid" ], tooltip, charList, raidList );
    end
    if( self.config.profile.worldBoss.show ) then
        populateWorldBossData( L["World Boss"], tooltip, charList, worldBossList );
    end
    if( self.config.profile.emissary.show ) then
        populateEmissaryData( L["Emissary"], tooltip, charList, emissaryList );
    end
    if( self.config.profile.weeklyQuest.show ) then
        populateWeeklyQuestData( L["Repeatable Quest"], tooltip, charList, weeklyQuestList );
    end
    if( self.config.profile.currency.show ) then
        populateCurrencyData( L["Currency"], tooltip, charList, currencyDisplayList );
    end

    local lineNum = tooltip:AddLine( );
    tooltip:SetCell( lineNum, 1, "* " .. L["Right-click for configuration menu"], nil, "LEFT", #charList + 1 );
    tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );
    
    -- Use smart anchoring code to anchor the tooltip to our frame
    tooltip:SmartAnchorTo( frame );
    tooltip:SetAutoHideDelay( 0.25, frame );

    addMainColorBanding( tooltip );
    
    -- Show it, et voilà !
    tooltip:Show();
end --  addon:OnEnter
