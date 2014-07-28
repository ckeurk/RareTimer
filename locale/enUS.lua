local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", "enUS", true)

--Command strings
L["CmdListHeading"] = "RareTimer status list:"

--Time strings
L["s"] = true -- Seconds
L["m"] = true -- Minutes
L["h"] = true -- Hours
L["d"] = true -- Days
L["ago"] = true

-- State strings
L["StateUnknown"] = 'Unknown'
L["StateKilled"] = 'Killed at %s'
L["StateDead"] = 'Killed at or before %s'
L["StatePending"] = 'Due to spawn before %s'
L["StateAlive"] = 'Alive'
L["StateInCombat"] = 'In combat'
L["StateExpired"] = 'Unknown (last seen %s)'

-- Mob names
L["Scorchwing"] = true
