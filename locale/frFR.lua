local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", "frFR",false)
if not L then return end
--
--Command strings
L["CmdListHeading"] = "RareTimer status list:" 

--Time strings
L["s"] = "s" -- Seconds
L["m"] = "m" -- Minutes
L["h"] = "h" -- Hours
L["d"] = "j" -- Days

-- State strings
L["StateUnknown"] = 'Inconnu'
L["StateKilled"] = 'Tué à %s'
L["StateDead"] = 'Tué au plus tard à %s'
L["StatePending"] = 'Devrait reparaitre avant %s'
L["StateAlive"] = 'En vie (%s)'
L["StateInCombat"] = 'En combat'
L["StateExpired"] = 'Inconnu (vu la dernière fois à %s)'
 
-- Mob names
L["Scorchwing"] = 'Ailardente'

