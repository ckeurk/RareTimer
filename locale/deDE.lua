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
L["StateUnknown"] = 'Unbekannt'
L["StateKilled"] = 'Bei %s getötet'
L["StateDead"] = 'Bei oder vor %s Uhr getötet'
L["StatePending"] = 'Aufgrund vor %s laichen'
L["StateAlive"] = 'Alive (ab %s Uhr)'
L["StateInCombat"] = 'im Kampf (%d%%)'
L["StateExpired"] = 'Unbekannt (zuletzt gesehen %s)'
L["StateTimerSoon"] = 'Kurz vor dem Start (%s)'
L["StateTimerTick"] = 'Begann um %s'
L["StateTimerRunning"] = 'Nächste Veranstaltung %s'

-- Mob names
L["Aggregor the Dust Eater"] = "Aggregor der Staubfresser"
L["Bugwit"] = "Kleinsinn"
L["Critical Containment"] = "Kritische Isolation"
L["Defensive Protocol Unit"] = "Defensivprotokolleinheit"
L["Doomthorn the Ancient"] = "Schicksalsdorn der Alte"
L["Grendelus the Guardian"] = "Grendelus der Wächter"
L["Grinder"] = "Schleifer"
L["Hoarding Stemdragon"] = "Hortender Stieldrache"
L["KE-27 Sentinel"] = "Wache KE-27"
L["King Honeygrave"] = "König Honiggrab"
L["Kraggar the Earth-Render"] = "Kraggar der Erdreißer"
L["Metal Maw"] = "Laserschlund"
L["Metal Maw Prime"] = "Laserschlund Prime"
L["Scorchwing"] = "Sengschwinge"
L["Subject J - Fiend"] = "Subjekt J - Scheusal"
L["Subject K - Brute"] = "Subjekt K - Widerling"
L["Subject Tau"] = "Objekt: Tau"
L["Subject V - Tempest"] = "Subjekt V - Sturm"
L["Zoetic"] = "Zoetik"
L["Star-Comm Basin"] = "Starkom Becken"