--[[
    This file is to deal with the code to generate the lockout table/vector and
    to handle the refresh of data and deletion of stale data
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):NewAddon( addonName, "AceConsole-3.0", "AceEvent-3.0", "AceBucket-3.0" );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

--_G.LockedOut = addon;

-- Upvalues
local next, time =
      next, time;

-- cache lua functions
local InterfaceOptionsFrame_OpenToCategory, GetCurrencyInfo, GetItemInfo, GetMacroIcons, GetAccountExpansionLevel =    -- variables
      InterfaceOptionsFrame_OpenToCategory, GetCurrencyInfo, GetItemInfo, GetMacroIcons, GetAccountExpansionLevel      -- lua functions
      
function addon:getConfigOptions()

    local anchorOptions = {
        ["cell"] = L["At cursor location"],
        ["parent"] = L["At bottom of frame"]
    }
    
    local currencyOptions = {
                                ["short"] = L["Short"],
                                ["long"] = L["Long"]
                            };
    
    local currencySortOptions = {};
    for key, data in next, self:getCurrencyOptions() do
        currencySortOptions[ key ] = data.description;
    end
    
    local characterSortOptions = {}
    for key, data in next, self:getCharSortOptions() do
        characterSortOptions[ key ] = data.description;
    end
    
    local currencyList = { };
    for ndx, currencyData in next, self:getCurrencyList() do
        if( currencyData.show ) then
            if( currencyData.icon == nil ) then
                if( currencyData.type == "C" ) then
                    _, _, currencyData.icon = GetCurrencyInfo( currencyData.ID );
                else
                    _, _, _, _, _, _, _, _, _, currencyData.icon = GetItemInfo( currencyData.ID );
                end;
            end

            currencyList[ currencyData.ID ] = (currencyData.icon == nil ) and "" or currencyData.icon .. currencyData.name;
        end
    end

    local charList = {};
    for key, value in next, addon:getCharacterList() do
        charList[ key ] = value;
    end

    local configOptions = {
		type = "group",
		name = addonName,
		args = {
			--[[
			enableAddon = {
			  order = 1,
			  name = L["Enable"],
			  desc = L["Enables / disables the addon"],
			  type = "toggle",
			  set = function(info,val) self.config.global.enabled = val; end,
			  get = function(info) return self.config.global.enabled end
			},
			--]]
			generalHeader={
			  order = 1,
			  name = L["General Options"],
			  type = "header",
			},
			currentRealmOnly = {
			  order = 2,
			  name = L["Current Realm"],
			  desc = L["Show characters from current realm only"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.general.currentRealm = val; end,
			  get = function(info) return self.config.profile.general.currentRealm end
			},
            showRealmHeader = {
			  order = 3,
			  name = L["Show Realm"],
			  desc = L["Show the realm header"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.general.showRealmHeader = val; end,
			  get = function(info) return self.config.profile.general.showRealmHeader end
			},
            configureFrameScale = {
			  order = 4,
			  name = "Frame Scale",
			  desc = "Configure the scale of the window",
			  type = "range",
              min = 0.50,
              max = 1.50,
              step = 0.05,
			  set = function(info,val)
                        self.config.profile.general.frameScale = val;
                        
                        if( addon.tooltip ) then
                            addon.tooltip:SetScale( val );
                        end
                    end,
			  get = function(info) return self.config.profile.general.frameScale end
            },
            showCharFirst = {
			  order = 5,
			  name = L["Show Active First"],
			  desc = L["Show logged in char first"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.general.loggedInFirst = val; end,
			  get = function(info) return self.config.profile.general.loggedInFirst end
			},
			showMinimapIcon = {
			  order = 6,
			  name = L["Hide Icon"],
			  desc = L["Show Minimap Icon"],
			  type = "toggle",
			  set = function(info,val)
                                    self.config.profile.minimap.hide = val;
                                    if( self.config.profile.minimap.hide ) then
                                        self.icon:Hide( addonName );
                                    else
                                        self.icon:Show( addonName );
                                    end
                                end,
			  get = function(info) return self.config.profile.minimap.hide end
			},
            characterSort = {
			  order = 7,
			  name = L["Sort Chars By"],
			  desc = L["Configure how characters are sorted in the list"],
			  type = "select",
			  style = "dropdown",
			  values = characterSortOptions,
			  set = function(info,val) self.config.profile.general.charSortBy = val; end,
			  get = function(info) return self.config.profile.general.charSortBy end
			},
            setAnchorPoint = {
			  order = 8,
			  name = L["Anchor To"],
			  desc = L["Choose where hover tooltip displays"],
			  type = "select",
			  style = "dropdown",
			  values = anchorOptions,
			  set = function(info,val) self.config.profile.general.anchorPoint = val; end,
			  get = function(info) return self.config.profile.general.anchorPoint end
			},
			minimapIconList = {
			  order = 9,
			  name = L["Choose Icon (reload ui)"],
			  desc = L["Choose icon for addon - requires ui refresh or login/logout"],
			  type = "select",
			  values = addon:getIconOptions(),
			  set = function(info,val) self.config.profile.minimap.addonIcon = val; end,
			  get = function(info) return self.config.profile.minimap.addonIcon end
			},
			---[[
            charTrackWhen = {
			  order = 10,
			  name = "Start Tracking Level",
			  desc = "Start tracking characters greater than or equal to level below",
			  type = "range",
              min = 1,
              max = MAX_PLAYER_LEVEL_TABLE[ GetAccountExpansionLevel() ],
              step = 1,
			  set = function(info,val) self.config.profile.general.minTrackCharLevel = val; end,
			  get = function(info) return self.config.profile.general.minTrackCharLevel end
            },
			--]]
			charVisible = {
			  order = 11,
			  name = "Visible Characters",
			  desc = "Which characters should show in menu",
			  type = "multiselect",
			  values = charList,
			  set = function(info,key,val) self.config.profile.general.showCharList[key] = val; end,
			  get = function(info,key) return self.config.profile.general.showCharList[key] end
			},
			dungeonHeader={
			  order = 20,
			  name = L["Instance Options"],
			  type = "header",
			},
			dungeonShow = {
			  order = 21,
			  name = L["Show"],
			  desc = L["Show dungeon information"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.dungeon.show = val; end,
			  get = function(info) return self.config.profile.dungeon.show end
			},
			raidHeader={
			  order = 30,
			  name = L["Raid Options"],
			  type = "header",
			},
			raidShow = {
			  order = 31,
			  name = L["Show"],
			  desc = L["Show raid information"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.raid.show = val; end,
			  get = function(info) return self.config.profile.raid.show end
			},
			worldBossHeader={
			  order = 40,
			  name = L["World Boss Options"],
			  type = "header",
			},
			worldBossShow = {
			  order = 41,
			  name = L["Show"],
			  desc = L["Show world boss information"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.worldBoss.show = val; end,
			  get = function(info) return self.config.profile.worldBoss.show end
			},
			worldBossOnlyDead = {
			  order = 42,
			  name = L["Show when dead"],
			  desc = L["Show in list only when killed"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.worldBoss.showKilledOnly = val; end,
			  get = function(info) return self.config.profile.worldBoss.showKilledOnly end
			},
			emissaryHeader={
			  order = 50,
			  name = L["Emissary Options"],
			  type = "header",
			},
			emissaryShow = {
			  order = 51,
			  name = L["Show"],
			  desc = L["Show Emissary Information"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.emissary.show = val; end,
			  get = function(info) return self.config.profile.emissary.show end
			},
			weeklyQuestHeader={
			  order = 60,
			  name = L["Repeatable Quest Options"],
			  type = "header",
			},
			weeklyQuestShow = {
			  order = 61,
			  name = L["Show"],
			  desc = L["Show repeatable quest information"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.weeklyQuest.show = val; end,
			  get = function(info) return self.config.profile.weeklyQuest.show end
			},
			currencyHeader={
			  order = 100,
			  name = L["Currency Options"],
			  type = "header",
			},
			currencyShow = {
			  order = 101,
			  name = L["Show"],
			  desc = L["Show currency information"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.currency.show = val; end,
			  get = function(info) return self.config.profile.currency.show end
			},
			currencyShorten = {
			  order = 102,
			  name = L["Currency Display"],
			  desc = L["Configures currency display"],
			  type = "select",
			  style = "dropdown",
			  values = currencyOptions,
			  set = function(info,val) self.config.profile.currency.display = val; end,
			  get = function(info) return self.config.profile.currency.display end
			},
			currencySort = {
			  order = 102,
			  name = L["Sort By"],
			  desc = L["Configure how currency is sorted"],
			  type = "select",
			  style = "dropdown",
			  values = currencySortOptions,
			  set = function(info,val) self.config.profile.currency.sortBy = val; end,
			  get = function(info) return self.config.profile.currency.sortBy end
			},
			currencyVisible = {
			  order = 103,
			  name = L["Visible Currencies"],
			  desc = L["Select which currencies you'd like to see"],
			  type = "multiselect",
			  values = currencyList,
			  set = function(info,key,val) self.config.profile.currency.displayList[key] = val; end,
			  get = function(info,key) return self.config.profile.currency.displayList[key] end
			}
		}
	};
	
	return configOptions;
end

function addon:getDefaultOptions()

    local currencyListDefaults = {};
    for _, currencyData in next, self:getCurrencyList() do
        if( currencyData.show ) then
            currencyListDefaults[ currencyData.ID ] = (currencyData.expansionLevel == 6);
        else
            currencyListDefaults[ currencyData.ID ] = nil; -- if improperly flagged, remove from list
        end
    end

    local charList = {};
    for key, _ in next, addon:getCharacterList() do
        charList[ key ] = true;
    end

	local defaultOptions = {
		global = {
			enabled = true
		},
		profile = {
			minimap = {
                --[[
                     position can only be >= 0
                     so use this to fix the position saving issue
                     by forcing it to 0 later on if it == -1
                --]]
                minimapPos = -1,
                hide = false,
                addonIcon = "134244",
			},
			general = {
				currentRealm = false,
                showRealmHeader = true,
                loggedInFirst = true,
                anchorPoint = "cell",
                showCharList = charList,
                charSortBy = "rc",
                frameScale = 1.0,
                minTrackCharLevel = MAX_PLAYER_LEVEL_TABLE[ GetAccountExpansionLevel() ]
			},
			dungeon = {
				show = true
			},
			raid = {
				show = true
			},
			worldBoss = {
				show = true,
                showKilledOnly = true
			},
			currency = {
				show = true,
                display = "long",
                displayList = currencyListDefaults,
                sortBy = "en"
			},
            emissary = {
                show = true
            },
            weeklyQuest = {
                show = true
            }
		}
	}
	
	return defaultOptions;
end

--[[
    libdbicon doesn't trigger the update for some reason. so lets force the update outside first since
     -1 is an invalid value.  change it to a correct default of 0 - this fixes the issue with minimap position not saving
--]]
local function minimapPositionFix( self )
    if( self.config.profile.minimap.minimapPos == -1 ) then
        self.config.profile.minimap.minimapPos = 0;
    end
end

function addon:OnInitialize()
	local defaultOptions = self:getDefaultOptions();
    self.config = LibStub( "AceDB-3.0" ):New( "LockedOutConfig", defaultOptions, true );
    self.config:RegisterDefaults( defaultOptions );

    local LockedoutMo = LibStub( "LibDataBroker-1.1" ):NewDataObject( "Locked Out", {
        type = "data source",
        text = L[ "Locked Out" ],
        icon = self.config.profile.minimap.addonIcon,
        OnClick = function( frame, button ) self:OpenConfigDialog( button ) end,
        OnEnter = function( frame ) self:ShowInfo( frame ) end,
    } ); -- local LockedoutMo

    self.icon = LibStub( "LibDBIcon-1.0" );
    minimapPositionFix( self );
    self.icon:Register(addonName, LockedoutMo, self.config.profile.minimap)

    self.optionFrameName = addonName .. "OptionPanel"
    LibStub( "AceConfigRegistry-3.0" ):RegisterOptionsTable( self.optionFrameName, self:getConfigOptions() );
    self.optionFrame = LibStub( "AceConfigDialog-3.0" ):AddToBlizOptions( self.optionFrameName, addonName );
    self.optionFrame.default = function() self:ResetDefaults() end;
	self:RegisterChatCommand( "lo", "ChatCommand" );
	self:RegisterChatCommand( "lockedout", "ChatCommand" );

    -- events
    self:RegisterEvent( "PLAYER_ENTERING_WORLD", "EVENT_ResetExpiredData" );
    self:RegisterBucketEvent( "UNIT_QUEST_LOG_CHANGED", 1, "EVENT_FullCharacterRefresh" );
    self:RegisterEvent( "WORLD_QUEST_COMPLETED_BY_SPELL", "EVENT_FullCharacterRefresh" );
    self:RegisterEvent( "BAG_UPDATE", "EVENT_FullCharacterRefresh" );
    self:RegisterEvent( "TIME_PLAYED_MSG", "EVENT_TimePlayed" );
    self:RegisterEvent( "PLAYER_LOGOUT", "EVENT_Logout" );
    self:RegisterBucketEvent( "ENCOUNTER_END", 1, "EVENT_SaveToInstance" );
    self:RegisterBucketEvent( "CURRENCY_DISPLAY_UPDATE", 1, "EVENT_CoinUpdate" );
    
    self.toolTipShowing = false;
    self.loggingOut = false;
end

BINDING_NAME_LOCKEDOUT = L["Show/Hide the LockedOut tooltip"]
BINDING_HEADER_LOCKEDOUT = L["Locked Out"]

function LockedOut_ToggleMinimap( )
    self = addon;
    self.toolTipShowing = not self.toolTipShowing;
    self:ShowInfo( self.icon.objects[addonName], self.toolTipShowing );
end

function addon:ChatCommand( )
    self:OpenConfigDialog();
end

function addon:ResetDefaults()
    -- reset database here.
    self.config:ResetProfile();
    minimapPositionFix( self );
    self.icon:Refresh( addonName, self.config.profile.minimap );
    LibStub("AceConfigRegistry-3.0"):NotifyChange( self.optionFrameName );
end

function addon:OpenConfigDialog( button )
    self.config:RegisterDefaults( self:getDefaultOptions() );
    LibStub( "AceConfigRegistry-3.0" ):RegisterOptionsTable( self.optionFrameName, self:getConfigOptions() );

	if( button == nil) or ( button == "RightButton" ) then
		-- this command is buggy, open it twice to fix the bug.
		InterfaceOptionsFrame_OpenToCategory( self.optionFrame ); -- #1
		InterfaceOptionsFrame_OpenToCategory( self.optionFrame ); -- #2
	end
    
    --[[ this helps to build the currency table
    local currList = self:getCurrencyList();
    for ndx=1, 2000 do
        local name = GetCurrencyInfo( ndx );
        
        if( name ~= nil ) and ( name ~= "" ) then
            local found = false;
        
            for _, data in next, currList do
                if( data.ID == ndx ) then
                    found = true;
                    break;
                end
            end
        
            if( found == false ) then
                --print( "{ [" .. ndx .. "] = { ID=" .. ndx .. ", name=nil, expansionLevel=6 } }, -- " .. name );
                print( '{ ID=1533, name=nil, icon=nil, expansionLevel=6, type="C", show=true }, -- ' .. name );
            end
        end
    end
    --]]
end

function addon:EVENT_TimePlayed( event, timePlayed, currentPlayedLevel )
    local playerData = self:InitCharDB( );
    self.lastTimePlayedUpdate = time();
    
    playerData.timePlayed = { total = timePlayed, currentLevel = currentPlayedLevel };
end

function addon:EVENT_Logout( event )
    self.loggingOut = true;
    local playerData = self:InitCharDB( );
    
    playerData.lastLogin = time();
    
    -- means we fired before, and we can go ahead and force an update
    if( self.lastTimePlayedUpdate ) then
        local diff = playerData.lastLogin - self.lastTimePlayedUpdate;
        
        self:EVENT_TimePlayed( event, playerData.timePlayed.total + diff, playerData.timePlayed.currentLevel + diff ); 
    end
end

function addon:EVENT_CoinUpdate( )
    self:EVENT_FullCharacterRefresh( "CURRENCY_DISPLAY_UPDATE" );
end

function addon:EVENT_SaveToInstance( )
    -- end status == 1 means success
    self:EVENT_FullCharacterRefresh();
end

function addon:EVENT_ResetExpiredData( )
    self:InitCharDB()
    self:checkExpiredLockouts( );
    
    self.config:RegisterDefaults( self:getDefaultOptions() );
end

function addon:EVENT_FullCharacterRefresh( )
    self:Lockedout_GetCurrentCharData( "refresh" );
end
