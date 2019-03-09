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
local InterfaceOptionsFrame_OpenToCategory, GetCurrencyInfo, GetItemInfo, GetMacroIcons, GetAccountExpansionLevel, RequestRaidInfo, MAX_PLAYER_LEVEL_TABLE =    -- variables
      InterfaceOptionsFrame_OpenToCategory, GetCurrencyInfo, GetItemInfo, GetMacroIcons, GetAccountExpansionLevel, RequestRaidInfo, MAX_PLAYER_LEVEL_TABLE      -- lua functions

-- this allows me to override the blizzard function in the case of a "pre-patch" event.  e.g.: 8.0 (BfA) but Legion still active
local function getCurrentExpansionLevel()
    return GetAccountExpansionLevel();
end

local function getCurrentMaxLevel()
    local accountExpansion = getCurrentExpansionLevel();
    
    return MAX_PLAYER_LEVEL_TABLE[ accountExpansion ];
end

local function getGeneralOptionConfig( self )
    local anchorOptions = {
        ["cell"] = L["At cursor location"],
        ["parent"] = L["At bottom of frame"]
    }

    return {
        order  = 1,
        type = "group",
        name = L["Frame Options"],
        args = {
            minimapIconList = {
              order = 1,
              name = L["Choose Icon (reload ui)"],
              desc = L["Choose icon for addon - requires ui refresh or login/logout"],
              type = "select",
              values = addon:getIconOptions(),
              set = function(info,val) self.config.profile.minimap.addonIcon = val; end,
              get = function(info) return self.config.profile.minimap.addonIcon end
            },
            showMinimapIcon = {
              order = 2,
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
            configureFrameScale = {
              order = 3,
              name = L["Frame Scale"],
              desc = L["Configure the scale of the window"],
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
            setAnchorPoint = {
              order = 4,
              name = L["Anchor To"],
              desc = L["Choose where hover tooltip displays"],
              type = "select",
              style = "dropdown",
              values = anchorOptions,
              set = function(info,val) self.config.profile.general.anchorPoint = val; end,
              get = function(info) return self.config.profile.general.anchorPoint end
            },
            showResetTime = {
              order = 5,
              name = L["Show Reset Time"],
              desc = L["Show reset time instead of checkbox when completed"],
              type = "toggle",
              set = function(info,val) self.config.profile.general.showResetTime = val; end,
              get = function(info) return self.config.profile.general.showResetTime end
            },
        }
    };
end

local function getCharacterOptionConfig( self )
    local characterSortOptions = {}
    for key, data in next, self:getCharSortOptions() do
        characterSortOptions[ key ] = data.description;
    end
    
    local showCharList = {};
    for key, value in next, addon:getCharacterList() do
        showCharList[ key ] = value;
    end

    return {
        order  = 5,
        type = "group",
        name = L["Character Options"],
        args = {
            showRealmHeader = {
              order = 1,
              name = L["Show Realm"],
              desc = L["Show the realm header"],
              type = "toggle",
              set = function(info,val) self.config.profile.general.showRealmHeader = val; end,
              get = function(info) return self.config.profile.general.showRealmHeader end
            },
            currentRealmOnly = {
              order = 2,
              name = L["Current Realm"],
              desc = L["Show characters from current realm only"],
              type = "toggle",
              set = function(info,val) self.config.profile.general.currentRealm = val; end,
              get = function(info) return self.config.profile.general.currentRealm end
            },
            showCharFirst = {
              order = 3,
              name = L["Show Active First"],
              desc = L["Show logged in char first"],
              type = "toggle",
              set = function(info,val) self.config.profile.general.loggedInFirst = val; end,
              get = function(info) return self.config.profile.general.loggedInFirst end
            },
            characterSort = {
              order = 4,
              name = L["Sort Chars By"],
              desc = L["Configure how characters are sorted in the list"],
              type = "select",
              style = "dropdown",
              values = characterSortOptions,
              set = function(info,val) self.config.profile.general.charSortBy = val; end,
              get = function(info) return self.config.profile.general.charSortBy end
            },
            charTrackWhen = {
              order = 5,
              name = L["Start Tracking Level"],
              desc = L["Start tracking characters greater than or equal to level below"],
              type = "range",
              min = 1,
              max = getCurrentMaxLevel(),
              step = 1,
              set = function(info,val) self.config.profile.general.minTrackCharLevel = val; end,
              get = function(info) return self.config.profile.general.minTrackCharLevel end
            },
            charVisible = {
              order = 6,
              name = L["Visible Characters"],
              desc = L["Which characters should show in menu"],
              type = "multiselect",
              values = showCharList,
              set = function(info,key,val) self.config.profile.general.showCharList[key] = val; end,
              get = function(info,key) return self.config.profile.general.showCharList[key] end
            },
        }
    };
end

local function getDungeonHeaderConfig( self )
    return {
            order  = 10,
            name = L["Instance Options"],
            type = "group",
            args = {
                dungeonShow = {
                  order = 21,
                  name = L["Show"],
                  desc = L["Show dungeon information"],
                  type = "toggle",
                  set = function(info,val) self.config.profile.dungeon.show = val; end,
                  get = function(info) return self.config.profile.dungeon.show end
                },
            }
        };
end
   
local function getRaidHeaderConfig( self )
    return {
            order  = 20,
            name = L["Raid Options"],
            type = "group",
            args = {
                raidShow = {
                  order = 31,
                  name = L["Show"],
                  desc = L["Show raid information"],
                  type = "toggle",
                  set = function(info,val) self.config.profile.raid.show = val; end,
                  get = function(info) return self.config.profile.raid.show end
                },
            }
        }
end

local function getWorldBossHeaderConfig( self )
    return {
        order  = 30,
        name = L["World Boss Options"],
        type = "group",
        args = {
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
        }
    };
end

local function getEmissaryHeaderConfig( self )
    return {
        order  = 40,
        name = L["Emissary Options"],
        type = "group",
        args = {
            emissaryShow = {
              order = 51,
              name = L["Show"],
              desc = L["Show Emissary Information"],
              type = "toggle",
              set = function(info,val) self.config.profile.emissary.show = val; end,
              get = function(info) return self.config.profile.emissary.show end
            },
            emissaryExp = {
              order = 52,
              name = L["Emissary groups"],
              desc = L["Which emissary groups to display"],
              type = "multiselect",
              values = addon.EmissaryDisplayGroups,
              set = function(info,key,val) self.config.profile.emissary.displayGroup[ key ] = val; end,
              get = function(info,key) return self.config.profile.emissary.displayGroup[ key ] end
            },
        }
    };
end

local function getWeeklyQuestHeaderConfig( self )
    return {
        order  = 50,
        name = L["Repeatable Quest Options"],
        type = "group",
        args = {
            weeklyQuestShow = {
              order = 61,
              name = L["Show"],
              desc = L["Show repeatable quest information"],
              type = "toggle",
              set = function(info,val) self.config.profile.weeklyQuest.show = val; end,
              get = function(info) return self.config.profile.weeklyQuest.show end
            },
        }
    };
end

local function getCurrencyHeaderConfig( self )
    local currencyOptions = {
                                ["short"] = L["Short"],
                                ["long"] = L["Long"]
                            };
    
    local currencySortOptions = {};
    for key, data in next, self:getCurrencyOptions() do
        currencySortOptions[ key ] = data.description;
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

    return {
        order  = 60,
        name = L["Currency Options"],
        type = "group",
        args = {
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
            displayExpansion = {
              order = 103,
              name = L["Display Expansion"],
              desc = L["Display expansion abbreviation the currency belongs to"],
              type = "toggle",
              set = function(info,key,val) self.config.profile.currency.displayExpansion = val; end,
              get = function(info,key) return self.config.profile.currency.displayExpansion end
            },
            currencyVisible = {
              order = 104,
              name = L["Visible Currencies"],
              desc = L["Select which currencies you'd like to see"],
              type = "multiselect",
              values = currencyList,
              set = function(info,key,val) self.config.profile.currency.displayList[key] = val; end,
              get = function(info,key) return self.config.profile.currency.displayList[key] end
            },
        }
    };
end

function addon:getConfigOptions()
    local configOptions = {
    type = "group",
        childGroups = "tab",
    name = addonName,
    args = {
            generalOptGroup     = getGeneralOptionConfig( self ),
            characterOptGroup   = getCharacterOptionConfig( self ),
            dungeonHeader       = getDungeonHeaderConfig( self ),
            raidHeader          = getRaidHeaderConfig( self ),
            worldBossHeader     = getWorldBossHeaderConfig( self ),
            emissaryHeader      = getEmissaryHeaderConfig( self ),
            weeklyQuestHeader   = getWeeklyQuestHeaderConfig( self ),
            currencyHeader      = getCurrencyHeaderConfig( self ),
        }
    };

    return configOptions;
end

function addon:getDefaultOptions()
    local currencyListDefaults = {};
    for _, currencyData in next, self:getCurrencyList() do
        if( currencyData.show ) then
            currencyListDefaults[ currencyData.ID ] = (currencyData.expansionLevel == getCurrentExpansionLevel());
        else
            currencyListDefaults[ currencyData.ID ] = nil; -- if improperly flagged, remove from list
        end
    end

    local showCharList = {};
    for key, _ in next, addon:getCharacterList() do
        showCharList[ key ] = true;
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
                showCharList = showCharList,
                charSortBy = "rc",
                frameScale = 1.0,
                minTrackCharLevel = getCurrentMaxLevel(),
                showResetTime = false
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
                sortBy = "en",
                displayExpansion = true
      },
            emissary = {
                show = true,
                displayGroup = addon.EmissaryDisplayGroups
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

function addon:OnEnable()
    self:RegisterEvent( "PLAYER_ENTERING_WORLD", "EVENT_ResetExpiredData" );
    self:RegisterEvent( "ZONE_CHANGED_NEW_AREA", "EVENT_CheckEnteredInstance" );
    self:RegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED", "EVENT_CheckEnteredInstance" );
    self:RegisterBucketEvent( "UNIT_QUEST_LOG_CHANGED", 1, "EVENT_FullCharacterRefresh" );
    self:RegisterEvent( "BAG_UPDATE", "EVENT_FullCharacterRefresh" );
    self:RegisterEvent( "TIME_PLAYED_MSG", "EVENT_TimePlayed" );
    self:RegisterEvent( "PLAYER_LOGOUT", "EVENT_Logout" );
    self:RegisterEvent( "BOSS_KILL", "EVENT_SaveToInstance" );
    self:RegisterBucketEvent( "CURRENCY_DISPLAY_UPDATE", 1, "EVENT_CoinUpdate" );

    self:RegisterChatCommand( "lo", "ChatCommand" );
    self:RegisterChatCommand( "lockedout", "ChatCommand" );
end

function addon:OnDisable()
    self:UnRegisterEvent( "PLAYER_ENTERING_WORLD" );
    self:UnRegisterEvent( "ZONE_CHANGED_NEW_AREA" );
    self:UnRegisterEvent( "COMBAT_LOG_EVENT_UNFILTERED" );
    self:UnRegisterEvent( "UNIT_QUEST_LOG_CHANGED" );
    self:UnRegisterEvent( "BAG_UPDATE" );
    self:UnRegisterEvent( "TIME_PLAYED_MSG" );
    self:UnRegisterEvent( "PLAYER_LOGOUT" );
    self:UnRegisterEvent( "BOSS_KILL" );
    self:UnRegisterEvent( "CURRENCY_DISPLAY_UPDATE" );

    self:UnRegisterChatCommand( "lo" );
    self:UnRegisterChatCommand( "lockedout" );
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
    for ndx=1, 2500 do
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
                --print( '{ ID=' .. ndx .. ', name=nil, icon=nil, expansionLevel=7, type="C", show=true }, -- ' .. name );
                print( "{ [" .. ndx .. "] = { ID=" .. ndx .. ", name=nil, expansionLevel=" .. GetAccountExpansionLevel() .. " } }, -- " .. name );
            end
        end
    end
    --]]
end

function addon:EVENT_TimePlayed( event, timePlayed, currentPlayedLevel )
    addon:debug( "EVENT_TimePlayed: ", event );

    self.lastTimePlayedUpdate = time();
    self.playerDb.timePlayed = { total = timePlayed, currentLevel = currentPlayedLevel };
end

function addon:EVENT_Logout( event )
    addon:debug( "EVENT_Logout: ", event );

    self.loggingOut = true;
    self.playerDb.lastLogin = time();
    
    -- means we fired before, and we can go ahead and force an update
    if( self.lastTimePlayedUpdate ) then
        local diff = playerData.lastLogin - self.lastTimePlayedUpdate;
        
        self:EVENT_TimePlayed( event, playerData.timePlayed.total + diff, playerData.timePlayed.currentLevel + diff ); 
    end
end

function addon:EVENT_CoinUpdate( event )
    addon:debug( "EVENT_CoinUpdate: ", "CURRENCY_DISPLAY_UPDATE" );

    self:EVENT_FullCharacterRefresh( "CURRENCY_DISPLAY_UPDATE" );
end

function addon:EVENT_SaveToInstance( event )
    addon:debug( "EVENT_SaveToInstance: ", event );

    self:RegisterEvent( "UPDATE_INSTANCE_INFO", "EVENT_UpdateInstanceInfo" );
    RequestRaidInfo();
end

function addon:EVENT_UpdateInstanceInfo()
    self:UnregisterEvent( "UPDATE_INSTANCE_INFO" );

    self:Lockedout_BuildInstanceLockout();
end

function addon:EVENT_CheckEnteredInstance( event )
    addon:debug( "EVENT_CheckEnteredInstance: ", event );

    -- force a refresh every time something dies...in an effort to keep the latest time updating.
    if( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
        local _, eventType = CombatLogGetCurrentEventInfo();

        if( eventType ~= "UNIT_DIED" ) then
            return;
        end
    end

    self:IncrementInstanceLockCount();
end

function addon:EVENT_ResetExpiredData( event )
    addon:debug( "EVENT_ResetExpiredData: ", event );

    self:InitCharDB()
    self:checkExpiredLockouts( );

    self.config:RegisterDefaults( self:getDefaultOptions() );
end

function addon:EVENT_FullCharacterRefresh( event )
    addon:debug( "EVENT_FullCharacterRefresh: ", event );

    self:Lockedout_RebuildAll( );
end
