local addonName, _ = ...;

local L = LibStub( "AceLocale-3.0" ):NewLocale( addonName, "enUS", true );

-- addon name
L["Locked Out"] = "Locked Out";

-- tooltip labels and headers
L["Show/Hide the LockedOut tooltip"]    = "Show/Hide the LockedOut tooltip";
L["Realm"]                              = "Realm";
L["Character"]                          = "Character";
L["Dungeon"]                            = "Dungeon";
L["Raid"]                               = "Raid";
L["World Boss"]                         = "World Boss";
L["Currency"]                           = "Currency";
L["Emissary"]                           = "Emissary";
L["Repeatable Quest"]                   = "Repeatable Quest";
L["Character iLevels"]                  = "Character iLevels";
L["Defeated"]                           = "Defeated";
L["Available"]                          = "Available";
L["Right-click for configuration menu"] = "Right-click for configuration menu";
L["Keystone Helper"]                    = "+# is current keystone, [#] is best completed mythic";
L["*Resets in"]                         = "*Resets in";
L["Currency Display"]                   = "Currency Display";

-- configuration menu
-- * headers
L["Frame Options"]              = "Frame Options";
L["Character Options"]          = "Character Options";
L["Current Realm"]              = "Current Realm";
L["Show Realm"]                 = "Show Realm";
L["Show Active First"]          = "Show Active First";
L["Sort Chars By"]              = "Sort Chars By";
L["Instance Options"]           = "Instance Options";
L["Raid Options"]               = "Raid Options";
L["World Boss Options"]         = "World Boss Options";
L["Currency Options"]           = "Currency Options";
L["Emissary Options"]           = "Emissary Options";
L["Repeatable Quest Options"]   = "Repeatable Quest Options";

L["Short"]                      = "Short";
L["Long"]                       = "Long";
L["Expansion then Name"]        = "Expansion then Name";
L["Name then Expansion"]        = "Name then Expansion";
L["At cursor location"]         = "At cursor location";
L["At bottom of frame"]         = "At bottom of frame";
L["Realm then Name"]            = "Realm then Name";
L["Name then Realm"]            = "Name then Realm";

-- * labels
L["Enable"]                     = "Enable";
L["Show"]                       = "Show";
L["Hide Icon"]                  = "Hide Icon";
L["Show when dead"]             = "Show when dead";
L["Sort By"]                    = "Sort By";
L["Visible Currencies"]         = "Visible Currencies";
L["Display Expansion"]          = "Display Expansion";
L["Anchor To"]                  = "Anchor To";
L["Show Reset Time"]            = "Show Reset Time"    
L["Choose Icon (reload ui)"]    = "Choose Icon (reload ui)";

-- * label descriptions
L["Enables / disables the addon"]                                   = "Enables / disables the addon";
L["Show characters from current realm only"]                        = "Show characters from current realm only";
L["Show the realm header"]                                          = "Hide the realm header";
L["Show logged in char first"]                                      = "Show logged in char first";
L["Configure how characters are sorted in the list"]                = "Configure how characters are sorted in the list";
L["Show Minimap Icon"]                                              = "Show Minimap Icon";
L["Show dungeon information"]                                       = "Show dungeon information";
L["Show raid information"]                                          = "Show raid information";
L["Show world boss information"]                                    = "Show world boss information";
L["Show in list only when killed"]                                  = "Show in list only when killed";
L["Show currency information"]                                      = "Show currency information";
L["Configures currency display"]                                    = "Configures currency display";
L["Show Emissary Information"]                                      = "Show Emissary Information";
L["Show repeatable quest information"]                              = "Show repeatable quest information";
L["Configure how currency is sorted"]                               = "Configure how currency is sorted";
L["Select which currencies you'd like to see"]                      = "Select which currencies you'd like to see";
L["Display expansion abbreviation the currency belongs to"]         = "Display expansion abbreviation the currency belongs to";
L["Choose where hover tooltip displays"]                            = "Choose where hover tooltip displays";
L["Show reset time instead of checkbox when completed"]             = "Show reset time instead of checkbox when completed"
L["Choose icon for addon - requires ui refresh or login/logout"]    = "Choose icon for addon - requires ui refresh or login/logout";

-- difficulty mapping full
L["Unknown"]            = "Unknown";
L["Normal"]             = "Normal";
L["Heroic"]             = "Heroic";
L["Mythic"]             = "Mythic";
L["Lfr"]                = "Lfr";
L["Timewalking"]        = "Timewalking";

-- difficulty mapping abbreviation
L["U"]  = "U";
L["N"] 	= "N";
L["H"] 	= "H";
L["M"]  = "M";
L["L"]  = "L";
L["T"]  = "T";

-- server reset
L["Instances Reset"]            = "Instances Reset";

-- quest.lua mappings
L["Blingtron"]                  = "Blingtron";
L["Instant Complete"]           = "Instant Complete";
L["Dalaran Weekly"]             = "Dalaran Weekly";
L["Seal of Fate"]               = "Seal of Fate";
L["WoW 13th - Bosses"]          = "WoW 13th - Bosses";
L["WoW 13th - Lore."]           = "WoW 13th - Lore.";
L["Argus - Pristine Argunite"]  = "Argus - Pristine Argunite";
L["Argus - Invasions"]          = "Argus - Invasions";
L["Argus - Cheap Ridgestalker"] = "Argus - Cheap Ridgestalker";
L["Argus - Cheap Void-Purged"]  = "Argus - Cheap Void-Purged";
L["Argus - Cheap Lightforged"]  = "Argus - Cheap Lightforged";
L["Daily Heroic (essences)"]    = "Daily Heroic (essences)";
L["Daily Heroic"]               = "Daily Heroic";
L["Island Expeditions"]         = "Island Expeditions";

-- expansion abbreviations
L["Van"]    = "Van";
L["BC"]     = "BC";
L["WotLK"]  = "WotLK";
L["Cata"]   = "Cata";
L["MoP"]    = "MoP";
L["WoD"]    = "WoD";
L["Leg"]    = "Leg";
L["BfA"]    = "BfA";
