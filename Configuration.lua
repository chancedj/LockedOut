--[[
    This file is to deal with the code to generate the lockout table/vector and
    to handle the refresh of data and deletion of stale data
--]]
local addonName, _ = ...;

-- libraries
local addon = LibStub( "AceAddon-3.0" ):NewAddon( addonName, "AceConsole-3.0", "AceEvent-3.0" );
local L     = LibStub( "AceLocale-3.0" ):GetLocale( addonName, false );

-- cache lua functions
local InterfaceOptionsFrame_OpenToCategory, GetCurrencyInfo, GetItemInfo, GetMacroIcons =    -- variables
      InterfaceOptionsFrame_OpenToCategory, GetCurrencyInfo, GetItemInfo, GetMacroIcons      -- lua functions
      
function addon:getConfigOptions()
    --[[
    local iconList = GetMacroIcons( nil );

    local iconDb = {};
    for ndx, textureId in next, iconList do
        iconDb[ textureId ] = "|T" .. textureId .. ":0|t"
    end
    --]]
    
    local anchorOptions = {
        ["cell"] = L["At cursor location"],
        ["parent"] = L["At bottom of frame"]
    }
    
    local currencyOptions = {
                                ["short"] = L["Short"],
                                ["long"] = L["Long"]
                            };
    
    local currencySortOptions = {};

    for key, data in next, addon:getCurrencyOptions() do
        currencySortOptions[ key ] = data.description;
    end
    
    local currencyList = { };

    for ndx, currencyData in next, addon:getCurrencyList() do
        if( currencyData.show ) then
            if( currencyData.icon == nil ) then
                if( currencyData.type == "C" ) then
                    _, _, currencyData.icon = GetCurrencyInfo( currencyData.ID );
                else
                    _, _, _, _, _, _, _, _, _, currencyData.icon = GetItemInfo( currencyData.ID );
                end;
            end

            currencyList[ currencyData.ID ] = currencyData.icon .. currencyData.name;
        end
    end

    local charList = {};
    
    for realmName, characters in next, LockoutDb do
        for charNdx, charData in next, characters do
            charList[ realmName .. "." .. charData.charName ] = realmName .. " - " .. charData.charName;
        end
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
			  order = 10,
			  name = L["General Options"],
			  type = "header",
			},
			currentRealmOnly = {
			  order = 11,
			  name = L["Current Realm"],
			  desc = L["Show characters from current realm only"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.general.currentRealm = val; end,
			  get = function(info) return self.config.profile.general.currentRealm end
			},
            showRealmHeader = {
			  order = 12,
			  name = L["Show Realm"],
			  desc = L["Show the realm header"],
			  type = "toggle",
			  set = function(info,val) self.config.profile.general.showRealmHeader = val; end,
			  get = function(info) return self.config.profile.general.showRealmHeader end
			},
			showMinimapIcon = {
			  order = 13,
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
            setAnchorPoint = {
			  order = 14,
			  name = L["Anchor To"],
			  desc = L["Choose where hover tooltip displays"],
			  type = "select",
			  style = "dropdown",
			  values = anchorOptions,
			  set = function(info,val) self.config.profile.general.anchorPoint = val; end,
			  get = function(info) return self.config.profile.general.anchorPoint end
			},
			charVisible = {
			  order = 15,
			  name = "Visible Characters",
			  desc = "Which characters should show in menu",
			  type = "multiselect",
			  values = charList,
			  set = function(info,key,val) self.config.profile.general.showCharList[key] = val; end,
			  get = function(info,key) return self.config.profile.general.showCharList[key] end
			},
			--[[
			minimapIconList = {
			  order = 19,
			  name = "Choose Icon",
			  desc = "Choose icon for addon",
			  type = "select",
			  values = iconList
			},
			--]]
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
    for _, currencyData in next, addon:getCurrencyList() do
        if( currencyData.show ) then
            currencyListDefaults[ currencyData.ID ] = (currencyData.expansionLevel == 6);
        else
            currencyListDefaults[ currencyData.ID ] = nil; -- if improperly flagged, remove from list
        end
    end

    local charList = {};
    
    for realmName, characters in next, LockoutDb do
        for charNdx, charData in next, characters do
            charList[ realmName .. "." .. charData.charName ] = true;
        end
    end

	local defaultOptions = {
		global = {
			enabled = true
		},
		profile = {
			minimap = {
				hide = false
			},
			general = {
				currentRealm = false,
                showRealmHeader = true,
                anchorPoint = "cell",
                showCharList = charList
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

function addon:OnInitialize()
    local LockedoutMo = LibStub( "LibDataBroker-1.1" ):NewDataObject( "Locked Out", {
        type = "data source",
        text = L[ "Locked Out" ],
        icon = "Interface\\Icons\\Inv_misc_key_10",
        OnClick = function( frame, button ) self:OpenConfigDialog( button ) end,
        OnEnter = function( frame ) self:ShowInfo( frame ) end,
    } ); -- local LockedoutMo

	local defaultOptions = self:getDefaultOptions();
    self.config = LibStub( "AceDB-3.0" ):New( "LockedOutConfig", defaultOptions, true );
    self.config:RegisterDefaults( defaultOptions );

    self.icon = LibStub( "LibDBIcon-1.0" );
    self.icon:Register(addonName, LockedoutMo, self.config.profile.minimap)

    self.optionFrameName = addonName .. "OptionPanel"
    LibStub( "AceConfigRegistry-3.0" ):RegisterOptionsTable( self.optionFrameName, self:getConfigOptions() );
    self.optionFrame = LibStub( "AceConfigDialog-3.0" ):AddToBlizOptions( self.optionFrameName, addonName );
    self.optionFrame.default = function() self:ResetDefaults() end;
	self:RegisterChatCommand( "lo", "ChatCommand" );
	self:RegisterChatCommand( "lockedout", "ChatCommand" );

    -- events
    self:RegisterEvent( "PLAYER_ENTERING_WORLD", "FullCharacterRefresh" );
    self:RegisterEvent( "UNIT_QUEST_LOG_CHANGED", "FullCharacterRefresh" );
    self:RegisterEvent( "UNIT_SPELLCAST_SUCCEEDED", "FullCharacterRefresh" );
end

function addon:ChatCommand()
	self:OpenConfigDialog();
end

function addon:ResetDefaults()
    -- reset database here.
    self.config:ResetProfile();
    LibStub("AceConfigRegistry-3.0"):NotifyChange( self.optionFrameName );
end

function addon:OpenConfigDialog( button )
	if( button == nil) or ( button == "RightButton" ) then
		-- this command is buggy, open it twice to fix the bug.
		InterfaceOptionsFrame_OpenToCategory( self.optionFrame ); -- #1
		InterfaceOptionsFrame_OpenToCategory( self.optionFrame ); -- #2
	end
    
    --[[ this helps to build the currency table
    for ndx=1, 2000 do
        local name = GetCurrencyInfo( ndx );
        
        if( name ~= nil ) and ( name ~= "" ) then
            print( "{ [" .. ndx .. "] = { ID=" .. ndx .. ", getName=function() return '' end, expansionLevel=1 } }, -- " .. name );
        end
    end
    --]]
end

local InstantComplete = {
    ["219540"] = true,
    ["221557"] = true,
    ["221561"] = true,
    ["221587"] = true,
    ["221597"] = true,
    ["221602"] = true
}

function addon:FullCharacterRefresh( event, unitID, spell, rank, lineID, spellID )
    addon:debug( "event fired: " .. event );
    addon:debug( "Reset: ", GetQuestResetTime() );
    addon:debug( "Quest Reset: ", self:getDailyLockoutDate() );
    if( event ~= "UNIT_SPELLCAST_SUCCEEDED" ) then
        self:Lockedout_GetCurrentCharData();
    elseif( event == "UNIT_SPELLCAST_SUCCEEDED" ) then
        local status = InstantComplete[ spellID ];
        if(  status ~= nil ) and ( status ) then
            print( "spell - refreshing: " .. spell .. " - " .. spellID );
            self:Lockedout_GetCurrentCharData();
        end
    end
end
