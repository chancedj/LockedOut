--[[
    This file is for dealing with handling the minimap creation and display
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):GetAddon( addonName );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- Upvalues
local next, tonumber, table, time, date, strsplit, tsort, mfloor, abs =           -- variables
      next, tonumber, table, time, date, strsplit, table.sort, math.floor, math.abs    -- lua functions

-- cache blizzard function/globals
local SecondsToTime, READY_CHECK_NOT_READY_TEXTURE, READY_CHECK_READY_TEXTURE  =    -- variables
      SecondsToTime, READY_CHECK_NOT_READY_TEXTURE, READY_CHECK_READY_TEXTURE       -- blizzard api
      
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

function addon:aquireEmptyTooltip( ttName )
    self.openSubTooltips = self.openSubTooltips or {};
    if( #self.openSubTooltips > 0 ) then
        -- close all open sub tooltips.
        for ndx, openTTName in next, self.openSubTooltips do
            local tt = LibQTip:Acquire( openTTName );
            LibQTip:Release( tt );
            self.openSubTooltips[ ndx ] = nil;
        end
    end
    
    local tooltip = LibQTip:Acquire( ttName );

    self.openSubTooltips[ #self.openSubTooltips + 1 ] = ttName;

    if( #tooltip.lines > 0 ) then
        LibQTip:Release( tooltip );
        tooltip = LibQTip:Acquire( ttName );
    end

    tooltip:SetScale( addon.config.profile.general.frameScale );
    
    return tooltip
end

local function setAnchorToTooltip( tooltip, linenum, cellnum )
    local parentTT = LibQTip:Acquire( "LockedoutTooltip" );
    
    tooltip:SetFrameLevel( parentTT:GetFrameLevel() + 10 );
    
    if( addon.config.profile.general.anchorPoint == "parent" ) then
        tooltip:SmartAnchorTo( parentTT );
    else
        tooltip:SmartAnchorTo( parentTT.lines[ linenum ].cells[ cellnum ] );
    end

    tooltip:SetAutoHideDelay( 0.1, parentTT.lines[ linenum ].cells[ cellnum ] );
    
    addPopupColorBanding( tooltip );
end

local function getDisplayTime( displayTime )
    if( getDisplayTime ) then
        return "|cFFFF0000" .. SecondsToTime( displayTime - GetServerTime() ) .. "|r";
    else
        return "";
    end;
end

local function displayReset( self )
    local ttName = self.anchor:getTTName();
    local tooltip = addon:aquireEmptyTooltip( ttName );
    
    tooltip:SetColumnLayout( 2 );
    local ln = tooltip:AddLine( );
    tooltip:SetCell( ln, 1, "|cFF00FF00" .. L["*Resets in"] .. "|r", nil, "CENTER" );
    tooltip:SetCell( ln, 2, getDisplayTime( self.anchor.data.resetDate ), nil, "CENTER" );
    tooltip:SetLineScript( ln, "OnEnter", emptyFunction );                -- empty function allows the background to highlight

    setAnchorToTooltip( tooltip, self.anchor.lineNum, self.anchor.cellNum );
    addPopupColorBanding( tooltip );
    
    tooltip:Show();
end -- function( data )

local function handleResetDisplay( tooltip, lineNum, colNdx, anchor, data )
    if( data.displayText ~= "" ) then
        if( addon.config.profile.general.showResetTime ) then
            anchor.displayTT  = emptyFunction;
            tooltip:SetCell( lineNum, colNdx, getDisplayTime( data.resetDate ), nil, "CENTER" );
        else
            anchor.displayTT  = displayReset;
            tooltip:SetCell( lineNum, colNdx, data.displayText, nil, "CENTER" );
        end
    end;
end;

local function populateInstanceData( header, tooltip, charList, instanceList )
    -- make sure it's not empty
    if ( next( instanceList ) == nil ) then return; end

    -- start adding the instances we have completed with any chacters
    local lineNum = tooltip:AddLine( );
    tooltip.lines[ lineNum ].is_header = true;
    tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );
    for encounterId, encounterName in next, instanceList do
        lineNum = tooltip:AddLine( encounterName );
        
        for colNdx, charData in next, charList do
            if (LockoutDb[ charData.realmName ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ].instances[ encounterId ] ~= nil) then
                local data = {};
                local instances = LockoutDb[ charData.realmName ][ charData.charNdx ].instances[ encounterId ];
                local instanceDisplay = {};
                for difficulty, instanceDetails in next, instances do
                    data[ #data + 1 ] = instanceDetails.displayText;
                end -- for difficulty, instanceDetails in next, instances

                instanceDisplay.displayTT = function( self )
                                                local ttName = self.anchor:getTTName();
                                                local tooltip = addon:aquireEmptyTooltip( ttName );
                                                
                                                local col = 2;
                                                
                                                tooltip:SetColumnLayout( 1 );
                                                tooltip:AddHeader( L["Boss Name"] );
                                                local hasBossData = false;
                                                local resetAssigned = true;
                                                for difficulty, instanceData in next, self.anchor.data do
                                                    if ( difficulty ~= addon.KEY_KEYSTONE ) and ( difficulty ~= addon.KEY_MYTHICBEST ) then
                                                        resetAssigned = false;
                                                        local col = tooltip:AddColumn( "CENTER" );

                                                        local ln = 1;
                                                        tooltip:SetCell( ln, col, difficulty, nil, "CENTER" );
                                                        tooltip:SetLineColor( ln, 1, 1, 1, 0.1 );
                                                        
                                                        if( col == 2 ) then
                                                            ln = tooltip:AddLine( );
                                                            tooltip:SetLineScript( ln, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
                                                        else
                                                            ln = ln + 1;
                                                        end

                                                        tooltip:SetCell( ln, 1, "|cFF00FF00" .. L["*Resets in"] .. "|r", nil, "CENTER" );
                                                        tooltip:SetCell( ln, col, "|cFFFF0000" .. SecondsToTime( instanceData.resetDate - GetServerTime() ) .. "|r", nil, "CENTER" );
                                                        for bossIndex, bossData in next, instanceData.bossData do
                                                            hasBossData = true;
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

                                                            local bossName = bossData.bossName;
                                                            
                                                            tooltip:SetCell( ln, 1, bossName, nil, "CENTER" );
                                                            tooltip:SetCell( ln, col, status, nil, "CENTER" );
                                                        end;
                                                    end -- for bossName, bossData in next, instanceData.bossData
                                                end -- for difficulty, instanceDetails in next, instances

                                                -- means only keystone is showing
                                                if( resetUnassigned ) then
                                                    local _, instanceData = next(self.anchor.data);
                                                    tooltip:AddColumn( "CENTER" );
                                                    tooltip:SetCell( 1, 1, "|cFF00FF00" .. L["*Resets in"] .. "|r", nil, "CENTER" );
                                                    tooltip:SetCell( 1, 2, "|cFFFF0000" .. SecondsToTime( instanceData.resetDate - GetServerTime() ) .. "|r", nil, "CENTER" );
                                                    tooltip:SetLineColor( 1, 1, 1, 1, 0.1 );
                                                end;

                                                -- display only if there is any boss data for the instance(s)
                                                if ( hasBossData ) then
                                                    setAnchorToTooltip( tooltip, self.anchor.lineNum, self.anchor.cellNum );
                                                    tooltip:Show();
                                                end;
                                            end -- function( data )
                instanceDisplay.deleteTT = emptyFunction;
                instanceDisplay.anchor = getAnchorPkt( "in", encounterName, instances, lineNum, colNdx + 1 );

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
    for bossKey, bossName in next, worldBossList do
        lineNum = tooltip:AddLine( bossName );
        
        for colNdx, charData in next, charList do
            if (LockoutDb[ charData.realmName ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ].worldBosses[ bossKey ] ~= nil) then
                local bossData = LockoutDb[ charData.realmName ][ charData.charNdx ].worldBosses[ bossKey ];
                
                local bossDisplay = {};
                handleResetDisplay( tooltip, lineNum, colNdx + 1, bossDisplay, bossData );
                bossDisplay.deleteTT   = emptyFunction;
                bossDisplay.anchor     = getAnchorPkt( "wb", bossName, bossData, lineNum, colNdx + 1 );

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
                    questDisplay.deleteTT  = emptyFunction;
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

local function popuateHolidayData( header, tooltip, charList, holidayList )
    -- make sure it's not empty
    if ( next( holidayList ) == nil ) then return; end

    -- start adding the instances we have completed with any chacters
    local lineNum = tooltip:AddLine( );
    tooltip.lines[ lineNum ].is_header = true;
    tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );

    local currentTime = GetServerTime();
    function countQuests( quests ) local c, t = 0, 0; for _, q in next, quests do t=t+1 if( q.completed ) then c=c+1; end; end; return c, t; end;
    for eventID, holidayData in next, holidayList do
        lineNum = tooltip:AddLine( );
        tooltip:SetCell( lineNum, 1, holidayData.title, nil, "LEFT" );
        
        for colNdx, charData in next, charList do
            if( holidayData.activeStatus == "PENDING" ) then
                tooltip:SetCell( lineNum, colNdx + 1, SecondsToTime( (60 * 60) - (currentTime - holidayData.startTime ) ) , nil, "LEFT" );
            else
                if (LockoutDb[ charData.realmName ] ~= nil) and
                   (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
                   (LockoutDb[ charData.realmName ][ charData.charNdx ].holidayEvents ~= nil) then

                    local eventData = LockoutDb[ charData.realmName ][ charData.charNdx ].holidayEvents[ eventID ] or {};

                    local holidayDisplay = {
                        anchor = getAnchorPkt( "hl", eventID, eventData, lineNum, colNdx + 1 );
                        displayTT = function( self )
                                                local ttName = self.anchor:getTTName();
                                                local tooltip = addon:aquireEmptyTooltip( ttName );
                                                
                                                tooltip:SetColumnLayout( 2 );
                                                tooltip:AddHeader( L["Quest Name"], L["Status"] );
                                                for questID, data in next, self.anchor.data do
                                                    local ln = tooltip:AddLine( );
                                                    tooltip:SetLineColor( ln, 1, 1, 1, 0.1 );
                                                    tooltip:SetCell( ln, 1, addon:getQuestTitleByID( questID ) );
                                                    tooltip:SetCell( ln, 2, data.displayText, nil, "CENTER" );
                                                end

                                                setAnchorToTooltip( tooltip, self.anchor.lineNum, self.anchor.cellNum );
                                                tooltip:Show();
                                            end, -- function( data )
                        deleteTT = emptyFunction
                    };
                    local completed, total = countQuests( eventData );
                    tooltip:SetCell( lineNum, colNdx + 1, completed .. "/" .. total, nil, "CENTER" );

                    tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", function() holidayDisplay:displayTT( ); end );    -- close out tooltip when leaving
                    tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", function() holidayDisplay:deleteTT( ); end );    -- open tooltip with info when entering cell.
                    tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );                -- empty function allows the background to highlight

                end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
            end
        end -- for colNdx, charData in next, charList
    end

    tooltip:AddSeparator( );
end -- popuateHolidayData

local function populateCurrencyData( header, tooltip, charList, currencyList )
    -- make sure it's not empty
    if ( next( currencyList ) == nil ) then return; end

    -- start adding the instances we have completed with any chacters
    local lineNum = tooltip:AddLine( );
    tooltip.lines[ lineNum ].is_header = true;
    tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );
    for _, currencyData in next, currencyList do
        local displayName = currencyData.name;

        if( addon.config.profile.currency.displayExpansion ) then
            displayName = displayName .. " (" .. addon.ExpansionAbbr[ currencyData.expansionLevel ] .. ")";
        end

        if( currencyData.icon ) then
            lineNum = tooltip:AddLine( currencyData.icon .. displayName );
        end
       
        ---[[
        for colNdx, charData in next, charList do
            if (LockoutDb[ charData.realmName ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
               (LockoutDb[ charData.realmName ][ charData.charNdx ].currency[ currencyData.ID ] ~= nil) then
                local currData = LockoutDb[ charData.realmName ][ charData.charNdx ].currency[ currencyData.ID ];

                local displayText = "";
                local currDisplay = {};
                currDisplay.anchor = {};
                currDisplay.displayTT = emptyFunction;
                currDisplay.deleteTT = emptyFunction;

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
                        ---[[
                        currDisplay.anchor = getAnchorPkt( "cr", currencyData.ID, currData, lineNum, colNdx + 1 );
                        currDisplay.displayTT = function( self )
                                                    local ttName = self.anchor:getTTName();
                                                    local tooltip = addon:aquireEmptyTooltip( ttName );
                                                    
                                                    tooltip:SetColumnLayout( 1 );
                                                    tooltip:AddHeader( L["Quest Name"] );
                                                    for ndx, questID in next, self.anchor.data.bonus do
                                                        addon:debug( "questID: " .. questID );
                                                        if( questID > 3 ) then
                                                            local title = addon:getQuestTitleByID( questID );
                                                            
                                                            if( title ) then
                                                                tooltip:AddLine( "|cffffff00|Hquest:" .. questID .. "|h[" .. title .. "]|h|r" );
                                                            end
                                                        end
                                                    end

                                                    setAnchorToTooltip( tooltip, self.anchor.lineNum, self.anchor.cellNum );
                                                    tooltip:Show();
                                                end
                        --]]
                        displayText = displayText .. "(" .. #currData.bonus .. ")";
                    end
                end

                tooltip:SetCell( lineNum, colNdx + 1, displayText, nil, "CENTER" );

                tooltip:SetCellScript( lineNum, colNdx + 1, "OnEnter", function() currDisplay:displayTT( ); end );    -- close out tooltip when leaving
                tooltip:SetCellScript( lineNum, colNdx + 1, "OnLeave", function() currDisplay:deleteTT( ); end );    -- open tooltip with info when entering cell.
                tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
            end -- if (LockoutDb[ charData.realmName ] ~= nil) and .....
        end -- for colNdx, charData in next, charList
        --]]
    end -- for currencyName, _ in next, currencyList

    tooltip:AddSeparator( );
end -- populateInstanceData

local BOSS_KILL_TEXT = "|T" .. READY_CHECK_READY_TEXTURE .. ":0|t";
local CHAR_DELETE_TEXT = "|T" .. READY_CHECK_NOT_READY_TEXTURE .. ":0|t";

local function sortEmissaries( a, b )
    if( a.code ~= b.code ) then
        return a.code < b.code;
    end

    return a.emissaryName < b.emissaryName;
end

local function populateEmissaryData( header, tooltip, charList, emissaryList )
    -- make sure it's not empty
    if ( next( emissaryList ) == nil ) then return; end

    -- start adding the instances we have completed with any chacters
    local lineNum = tooltip:AddLine( );
    tooltip.lines[ lineNum ].is_header = true;
    tooltip:SetCell( lineNum, 1, header, nil, "CENTER" );

    for expId, emissaryExpData in next, emissaryList do
        local sortedQuestIds = addon:getKeysSortedByValue( emissaryExpData, sortEmissaries );

        for _, questID in next, sortedQuestIds do
            local emissaryData = emissaryExpData[ questID ];

            lineNum = tooltip:AddLine( emissaryData.displayName );
            
            for colNdx, charData in next, charList do
                if (LockoutDb[ charData.realmName ] ~= nil) and
                   (LockoutDb[ charData.realmName ][ charData.charNdx ] ~= nil) and
                   (LockoutDb[ charData.realmName ][ charData.charNdx ].emissaries[ questID ] ~= nil) then
                    local emData = LockoutDb[ charData.realmName ][ charData.charNdx ].emissaries[ questID ];
                    local displayText = "";
                    if( emData.isComplete ) then
                        displayText = BOSS_KILL_TEXT;
                    elseif( emData.active ) then
                        displayText = emData.fullfilled .. "/" .. emData.required;
                    end

                    if( emData.paragonReady ) then
                        displayText = displayText .. " P";
                    end;
                    tooltip:SetCell( lineNum, colNdx + 1, displayText, nil, "CENTER" );
                end
                tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
            end -- for colNdx, charData in next, charList
        end -- for currencyName, _ in next, currencyList
    end

    tooltip:AddSeparator( );
end

local function shouldDisplayChar( realmName, playerData )
    addon:debug( realmName .. "." .. playerData.charName, playerData.currentLevel or -1 );
    
    return  ( addon.config.profile.general.showCharList[ realmName .. "." .. playerData.charName ] ) and
            ( playerData.currentLevel == nil or playerData.currentLevel >= addon.config.profile.general.minTrackCharLevel )
end

function addon:ShowInfo( frame, manualToggle )
    self:removeExpiredInstances();
    if( manualToggle ~= nil ) then
        if( not manualToggle ) then
            LibQTip:Release( self.tooltip );
            self.tooltip = nil;

            return;
        end
    end

    if ( self.tooltip ~= nil ) then
        LibQTip:Release( self.tooltip );
        self.tooltip = nil;
    end -- if ( self.tooltip ~= nil )
    
    -- Acquire a tooltip with 3 columns, respectively aligned to left, center and right
    local tooltip = LibQTip:Acquire( "LockedoutTooltip" );
    self.tooltip = tooltip;

    local realmCount = 0;
    local charList = {};
    local dungeonDisplayList = {};
    local raidDisplayList = {};
    local worldBossDisplayList = {};
    local currencyDisplayList = {};
    local emissaryDisplayList = { [ "6" ] = {}, [ "7" ] = {} }; -- initialize with the expansions
    local weeklyQuestDisplayList = {};
    local holidayDisplayList = {};

    local currencyMappingList = {};
    local CURRENCY_LIST = self:getCurrencyList();
    local CURRENCY_LIST_MAP = self:getCurrencyListMap();
    
    -- get list of characters and realms for the horizontal
    local dailyLockout = self:getDailyLockoutDate();
    for realmName, characters in next, LockoutDb do
        if( not self.config.profile.general.currentRealm ) or ( addon.currentRealm == realmName ) then
            realmCount = realmCount + 1;
            for charNdx, charData in next, characters do
                if( shouldDisplayChar( realmName, charData ) ) then
                    local tblNdx = #charList + 1;
                    charList[ tblNdx ] = {}
                    charList[ tblNdx ].charNdx = charNdx;
                    charList[ tblNdx ].realmName = realmName;
                    charList[ tblNdx ].charName = charData.charName;
                    charList[ tblNdx ].className = charData.className;

                    if( self.config.profile.general.loggedInFirst ) and
                      ( addon.currentRealm == realmName ) and 
                      ( addon.charDbIndex == charNdx ) then
                        charList[ tblNdx ].priority = 0;
                    else
                        charList[ tblNdx ].priority = 1;
                    end
                    
                    -- the get a list of all instances across characters for vertical
                    for encounterName, details in next, charData.instances do
                        local key, data = next( details );
                        
                        if ( data.isRaid ) then
                            raidDisplayList[ encounterName ] = encounterName;
                        else
                            dungeonDisplayList[ encounterName ] = encounterName;
                        end -- if ( data.isRaid )
                    end -- for encounterId, _ in next, instances
                    
                    for bossKey, bossData in next, charData.worldBosses do
                        local instanceID, bossID = strsplit( "|", bossKey );

                        if( instanceID ~= nil ) and ( bossID ~= nil ) then
                            worldBossDisplayList[ bossKey ] = addon:getWorldBossName( instanceID, bossID );
                        end
                    end -- for bossName, _ in next, charData.worldBosses
                    
                    for currID, currData in next, charData.currency do
                        local currNdx = CURRENCY_LIST_MAP[ currID ];
                        local curr = CURRENCY_LIST[ currNdx ];
                        
                        if( curr ~= nil ) and ( curr.name ~= nil ) and (curr.icon ~= nil ) and ( self.config.profile.currency.displayList[ currID ] ) then
                            currencyMappingList[ currID ] = currNdx;
                        end
                    end -- for currName, _ in next, charData.currency
                    
                    for questAbbr, questData in next, charData.weeklyQuests do
                        weeklyQuestDisplayList[ questAbbr ] = questData.name;
                    end
                    
                    for questID, emData in next, charData.emissaries do
                        local title = addon:getQuestTitleByID( questID );
                        if( title ~= nil and emData.expLevel ~= nil ) then
                            -- add a 10 second buffer - things get a little off when the reset date ends up short by a second or two..
                            local day;
                            if( emData.resetDate == -1 ) then
                                day = -1;
                            else
                                day = mfloor( abs( emData.resetDate + 10 - dailyLockout ) / (24 * 60 * 60) );
                            end

                            if( day >= 0 and day <= 3 ) then
                                self:debug( realmName .. "." .. charData.charName .. " title: " .. title .. " day: " .. day .. " resetDate: " .. emData.resetDate );
                                emissaryDisplayList[ emData.expLevel ][ questID ] = {
                                    displayName = addon.ExpansionAbbr[ tonumber(emData.expLevel) ] .. "(+" .. day .. ") " .. title,
                                    emissaryName = title,
                                    code = tostring( day )
                                }
                            elseif( emData.paragonReady ) then
                                self:debug( realmName .. "." .. charData.charName .. " title: " .. title .. " day: " .. day .. " resetDate: " .. emData.resetDate );
                                emissaryDisplayList[ emData.expLevel ][ questID ] = {
                                    displayName = addon.ExpansionAbbr[ tonumber(emData.expLevel) ] .. " " .. title,
                                    emissaryName = title,
                                    code = "P"
                                }
                            end
                        end
                    end
                end
            end -- for charName, instances in next, characters
        end
    end -- for realmName, characters in next, LockoutDb

    for key, val in next, emissaryDisplayList do
        if (not self.config.profile.emissary.displayGroup[ key ] ) then
            emissaryDisplayList[ key ] = nil;
        end
    end
    
    -- sort list by realm then character
    local charSort = self:getCharSortOptions();
    tsort( charList, charSort[ self.config.profile.general.charSortBy ].sortFunction );

    for currID, currNdx in next, currencyMappingList do
        currencyDisplayList[ #currencyDisplayList + 1 ] = CURRENCY_LIST[ currNdx ];
    end
    
    local currentHolidayEvents = self:Lockedout_GetCommingEvents();
    local currentTime = GetServerTime();
    for eventID, eventData in next, currentHolidayEvents do
        if ( eventData.startTime > currentTime ) then
            holidayDisplayList[ eventID ] = {
                activeStatus = "PENDING",
                startTime = eventData.startTime,
                title = eventData.title
            };
        else
            holidayDisplayList[ eventID ] = {
                activeStatus = "CURRENT",
                startTime = eventData.startTime,
                title = eventData.title
            };
        end
    end

    -- sort instance list
    tsort( dungeonDisplayList );
    tsort( raidDisplayList );
    tsort( worldBossDisplayList );
    local currSort = self:getCurrencyOptions();
    tsort( currencyDisplayList, currSort[ self.config.profile.currency.sortBy ].sortFunction );
    
    -- initialize the column count going forward
    tooltip:SetColumnLayout( #charList + 1 );

    -- Add a header filling only the first columns in the first 2 rows (Realm, Character)
    local deleteLineNum;
    local realmLineNum;
    local charLineNum;
    
    deleteLineNum = tooltip:AddHeader( "" ); -- delete column
    if( realmCount > 1 ) and ( self.config.profile.general.showRealmHeader ) then -- show realm only when multiple are involved
        realmLineNum = tooltip:AddHeader( L[ "Realm" ] ); -- realm column
    end
    charLineNum  = tooltip:AddHeader( L[ "Character" ] ); -- char column
    -- add the characters and realms across the header
    for colNdx, char in next, charList do
        tooltip:SetCell( deleteLineNum, colNdx + 1, CHAR_DELETE_TEXT, nil, "CENTER" );
        if( realmCount > 1 ) and ( self.config.profile.general.showRealmHeader ) then -- show realm only when multiple are involved
            local realmInstanceLockData = addon:getLockDataByRealm( char.realmName );
            local realmDisplay = {};
            realmDisplay.displayTT =    function( self )
                                            local ttName = self.anchor:getTTName();
                                            local tooltip = addon:aquireEmptyTooltip( ttName );
                                            tooltip:SetColumnLayout( 4 );

                                            if ( self.anchor.data ) then
                                                local currentTime = GetServerTime();
                                                line = tooltip:AddHeader( "" );
                                                tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                                tooltip:SetCell( line, 1, L["Locked Instances"], 4 );
                                                
                                                line = tooltip:AddHeader( "" );
                                                tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                                tooltip:SetCell( line, 1, L["Time Remaining"] );
                                                tooltip:SetCell( line, 2, L["Realm Name"] );
                                                tooltip:SetCell( line, 3, L["Char Name"] );
                                                tooltip:SetCell( line, 4, L["Instance Name"] );
                                                
                                                for k, p in next, self.anchor.data do
                                                    line = tooltip:AddHeader( "" );
                                                    tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                                    tooltip:SetCell( line, 1, SecondsToTime( (60 * 60) - (currentTime - p.timeSaved ) ) );
                                                    tooltip:SetCell( line, 2, p.realmName );
                                                    tooltip:SetCell( line, 3, p.charName );
                                                    tooltip:SetCell( line, 4, addon:GetInstanceName( p.instanceId ) );
                                                    tooltip:SetLineScript( line, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
                                                end
                                            end

                                            setAnchorToTooltip( tooltip, self.anchor.lineNum, self.anchor.cellNum );
                                            tooltip:Show();
                                        end 
            realmDisplay.deleteTT =     emptyFunction;
            realmDisplay.anchor = getAnchorPkt( "realm", char.realmName, realmInstanceLockData, realmLineNum, colNdx + 1 );

            tooltip:SetCell( realmLineNum, colNdx + 1, self:colorizeString( char.className, char.realmName .. " (" .. #realmInstanceLockData .. ")" ), nil, "CENTER" );
            tooltip:SetCellScript( realmLineNum, colNdx + 1, "OnEnter", function() realmDisplay:displayTT( ); end ); -- close out tooltip when leaving
            tooltip:SetCellScript( realmLineNum, colNdx + 1, "OnLeave", function() realmDisplay:deleteTT( ); end );     -- close out tooltip when leaving
        end
        local charData = LockoutDb[ char.realmName ][ char.charNdx ];
        local charInstanceLockData = addon:getLockDataByChar( char.realmName, char.charNdx );
        local charDisplay = {};
        charDisplay.displayTT = function( self )
                                    if ( charData.iLevel == nil ) then
                                        return;
                                    end

                                    local ttName = self.anchor:getTTName();
                                    local tooltip = addon:aquireEmptyTooltip( ttName );
                                    tooltip:SetColumnLayout( 2 );

                                    local line = tooltip:AddHeader( "" );
                                    tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                    tooltip:SetCell( line, 1, L["Character iLevels"], 2 );
                                    for k, p in next, self.anchor.data.iLevel do
                                        line = tooltip:AddLine( k, p );
                                        tooltip:SetLineScript( line, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
                                    end -- for k, p in next, charData.iLevel

                                    if ( self.anchor.data.timePlayed ) then
                                        line = tooltip:AddHeader( "" );
                                        tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                        tooltip:SetCell( line, 1, L["Time Played"], 2 );
                                        for k, p in next, self.anchor.data.timePlayed do
                                            line = tooltip:AddLine( k, SecondsToTime( p, false, false, 5 ) );
                                            tooltip:SetLineScript( line, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
                                        end
                                    end

                                    if ( self.anchor.data.lastLogin ) then
                                        line = tooltip:AddHeader( "" );
                                        tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                        tooltip:SetCell( line, 1, L["Last Login"] );
                                        tooltip:SetCell( line, 2, date( "%c", self.anchor.data.lastLogin ) );
                                        tooltip:SetLineScript( line, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
                                    end

                                    if ( self.anchor.data.instanceLockData ) then
                                        local currentTime = GetServerTime();
                                        line = tooltip:AddHeader( "" );
                                        tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                        tooltip:SetCell( line, 1, L["Locked Instances"], 2 );
                                        line = tooltip:AddHeader( "" );
                                        tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                        tooltip:SetCell( line, 1, L["Time Remaining"] );
                                        tooltip:SetCell( line, 2, L["Instance Name"] );
                                        for k, p in next, self.anchor.data.instanceLockData do
                                            line = tooltip:AddHeader( "" );
                                            tooltip:SetLineColor( line, 1, 1, 1, 0.1 );
                                            tooltip:SetCell( line, 1, SecondsToTime( (60 * 60) - (currentTime - p.timeSaved ) ) );
                                            tooltip:SetCell( line, 2, addon:GetInstanceName( p.instanceId ) );
                                            tooltip:SetLineScript( line, "OnEnter", emptyFunction );                -- empty function allows the background to highlight
                                        end
                                    end

                                    setAnchorToTooltip( tooltip, self.anchor.lineNum, self.anchor.cellNum );
                                    tooltip:Show();
                                end -- function( data )
        charDisplay.deleteTT = emptyFunction;
        charDisplay.deleteChar =    function( self )
                                        --LockoutDb[ char.realmName ][ char.charNdx ] = nil;
                                        addon:deleteChar( char.realmName, char.charNdx );

                                        local tooltip = LibQTip:Acquire( "LockedoutTooltip" );
                                        LibQTip:Release( tooltip );
                                    end
        charDisplay.anchor = getAnchorPkt( "ch", charData.charName, charData, charLineNum, colNdx + 1 );

        tooltip:SetCell( charLineNum, colNdx + 1, self:colorizeString( char.className, char.charName .. " (" .. #charInstanceLockData .. ")" ), nil, "CENTER" );

        tooltip:SetCellScript( deleteLineNum, colNdx + 1, "OnMouseDown", function() charDisplay:deleteChar( ); end ); -- close out tooltip when leaving
        tooltip:SetCellScript( charLineNum, colNdx + 1, "OnEnter", function() charDisplay:displayTT( ); end ); -- close out tooltip when leaving
        tooltip:SetCellScript( charLineNum, colNdx + 1, "OnLeave", function() charDisplay:deleteTT( ); end );     -- close out tooltip when leaving
    end -- for colNdx, char in next, charList

    tooltip:AddSeparator( );
    tooltip:AddSeparator( );

    local lineNum = 0;
    if( self.config.profile.dungeon.show ) then
        populateInstanceData( L[ "Dungeon" ], tooltip, charList, dungeonDisplayList );
        lineNum = tooltip:AddLine( );
        tooltip:SetCell( lineNum, 1, "* " .. L["Keystone Helper"], nil, "LEFT", #charList + 1 );
        tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );
    end
    if( self.config.profile.raid.show ) then
        populateInstanceData( L[ "Raid" ], tooltip, charList, raidDisplayList );
    end
    if( self.config.profile.worldBoss.show ) then
        populateWorldBossData( L["World Boss"], tooltip, charList, worldBossDisplayList );
    end
    if( self.config.profile.emissary.show ) then
        populateEmissaryData( L["Emissary"], tooltip, charList, emissaryDisplayList );
    end
    if( self.config.profile.weeklyQuest.show ) then
        populateWeeklyQuestData( L["Repeatable Quest"], tooltip, charList, weeklyQuestDisplayList );
    end
    if( self.config.profile.currency.show ) then
        populateCurrencyData( L["Currency"], tooltip, charList, currencyDisplayList );
    end
    if( true ) then
        popuateHolidayData( L["Holiday Events"], tooltip, charList, holidayDisplayList );
    end

    lineNum = tooltip:AddLine( );
    tooltip:SetCell( lineNum, 1, "* " .. L["Right-click for configuration menu"], nil, "LEFT", #charList + 1 );
    tooltip:SetLineScript( lineNum, "OnEnter", emptyFunction );
    
    -- Use smart anchoring code to anchor the tooltip to our frame
    tooltip:SmartAnchorTo( frame );
    if( manualToggle == nil ) then
        tooltip:SetAutoHideDelay( 0.25, frame );
    end

    addMainColorBanding( tooltip );
    tooltip:SetScale( addon.config.profile.general.frameScale );

    -- Show it, et voilà !
    tooltip:Show();
end --  addon:OnEnter
