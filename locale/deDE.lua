local Locale = "deDE"
local IsDefaultLocale = false
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", Locale, IsDefaultLocale)
if not L then return end

L["LocaleName"] = Locale

--Command strings
L["CmdListHeading"] = "RareTimer status list:"
L["AlertHeading"] = "RareTimer alert:"

--Time strings
L["s"] = true -- Seconds
L["m"] = true -- Minutes
L["h"] = true -- Hours
L["d"] = true -- Days

-- State strings
L["StateUnknown"] = 'Unknown'
L["StateKilled"] = 'Killed at %s'
L["StateDead"] = 'Killed at or before %s'
L["StatePending"] = 'Due to spawn before %s'
L["StateAlive"] = 'Alive (as of %s)'
L["StateInCombat"] = 'In combat (%d%%)'
L["StateExpired"] = 'Unknown (last seen %s)'

-- Mob names
L["Aggregor the Dust Eater"] = "Aggregor der Staubfresser"
L["Bugwit"] = "Kleinsinn"
L["Defensive Protocol Unit"] = "Defensivprotokolleinheit"
L["Doomthorn the Ancient"] = "Schicksalsdorn der Alte"
L["Grendelus the Guardian"] = "Grendelus der W�chter"
L["Grinder"] = "Schleifer"
L["Hoarding Stemdragon"] = "Hortender Stieldrache"
L["KE-27 Sentinel"] = "Wache KE-27"
L["King Honeygrave"] = "K�nig Honiggrab"
L["Kraggar the Earth-Render"] = "Kraggar der Erdrei�er"
L["Metal Maw"] = "Laserschlund"
L["Metal Maw Prime"] = "Laserschlund Prime"
L["Scorchwing"] = "Sengschwinge"
L["Subject J - Fiend"] = "Subjekt J - Scheusal"
L["Subject K - Brute"] = "Subjekt K - Widerling"
L["Subject Tau"] = "Objekt: Tau"
L["Subject V - Tempest"] = "Subjekt V - Sturm"
L["Zoetic"] = "Zoetik"
