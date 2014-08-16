local Locale = "frFR"
local IsDefaultLocale = false
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", Locale, IsDefaultLocale)
if not L then return end

L["LocaleName"] = Locale

--Heading strings
L["CmdListHeading"] = "RareTimer registre d'état:" 
L["AlertHeading"] = "RareTimer alerte:"
L["Name"] = "Nom"
L["Status"] = "Condition"
L["Last kill"] = "Tué"
L["Health"] = "Vie"

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
L["StateInCombat"] = 'En combat (%d%%)'
L["StateExpired"] = 'Inconnu (vu la dernière fois à %s)'
 
-- Mob names
L["Scorchwing"] = 'Ailardente'

