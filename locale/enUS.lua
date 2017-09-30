local addonName, _ = ...;

local L = LibStub( "AceLocale-3.0" ):NewLocale( addonName, "enUS", true );

-- addon name
L["Locked Out"] = "Locked Out";

-- tooltip labels and headers
L["Realm"]                              = "Realm";
L["Character"]                          = "Character";
L["Dungeon"]                            = "Dungeon";
L["Raid"]                               = "Raid";
L["World Boss"]                         = "World Boss";
L["Currency"]                           = "Currency";
L["Character iLevels"]                  = "Character iLevels";
L["Defeated"]                           = "Defeated";
L["Available"]                          = "Available";
L["Right-click for configuration menu"] = "Right-click for configuration menu";

-- configuration menu
-- * headers
L["General Options"]    = "General Options";
L["Current Realm"]      = "Current Realm";
L["Instance Options"]   = "Instance Options";
L["Raid Options"]       = "Raid Options";
L["World Boss Options"] = "World Boss Options";
L["Currency Options"]   = "Currency Options";

-- * labels
L["Enable"]     = "Enable";
L["Show"]       = "Show";
L["Hide Icon"]  = "Hide Icon";

-- * label descriptions
L["Enables / disables the addon"]               = "Enables / disables the addon";
L["Show characters from current realm only"]    = "Show characters from current realm only";
L["Show Minimap Icon"]                          = "Show Minimap Icon";
L["Show dungeon information"]                   = "Show dungeon information";
L["Show raid information"]                      = "Show raid information";
L["Show world boss information"]                = "Show world boss information";
L["Show currency information"]                  = "Show currency information";

-- difficulty mapping full
L["Unknown"]    = "Unknown";
L["Normal"]     = "Normal";
L["Heroic"]     = "Heroic";
L["Mythic"]     = "Mythic";
L["Lfr"]        = "Lfr";

-- difficulty mapping abbreviation
L["U"]  = "U";
L["N"] 	= "N";
L["H"] 	= "H";
L["M"]  = "M";
L["L"]  = "L";
