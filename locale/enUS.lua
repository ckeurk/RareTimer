local Locale = "enUS"
local IsDefaultLocale = true
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", Locale, IsDefaultLocale)

L["LocaleName"] = Locale

--Heading strings
L["CmdListHeading"] = "RareTimer status list:"
L["AlertHeading"] = "RareTimer alert:"
L["Name"] = true
L["Status"] = true
L["Last kill"] = true
L["Health"] = true

--Option strings
L["OptTargetTimeout"] = "Suppress alert after targeting (minutes)"
L["OptTargetTimeoutDesc"] = "Don't alert if we have targetted the mob within the timeout"
L["OptPlaySound"] = "Play sound"
L["OptPlaySoundDesc"] = "Play a sound when the alert is triggered"

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
L["StateInCombat"] = 'In combat'
L["StateExpired"] = 'Unknown (last seen %s)'

-- Mob names
L["Scorchwing"] = true
L["Scorchwing Scorchling"] = true
L["Honeysting Barbtail"] = true
