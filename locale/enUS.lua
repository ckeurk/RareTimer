local Locale = "enUS"
local IsDefaultLocale = true
local Silent = true
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", Locale, IsDefaultLocale, Silent)

L["LocaleName"] = Locale

--Heading strings
L["CmdListHeading"] = "RareTimer status list:"
L["AlertHeading"] = "RareTimer alert:"
L["Name"] = true
L["Status"] = true
L["Last kill"] = true
L["Health"] = true
L["OptSettingsHeader"] = "General Settings"
L["OptSnoozeHeader"] = "Snooze Settings"
L["OptAlertsHeader"] = "Alerts"

--Msgs
L["NewVersionMsg"] = "A new version of RareTimer is available."
L["ObsoleteVersionMsg"] = "RareTimer is out of date and will no longer receive updates from other clients."
L["SnoozeMsg"] = "RareTimer: Suppressing alerts for %s minutes."
L["SnoozeResetMsg"] = "RareTimer: Snooze reset."
L["Y"] = true -- Yes
L["N"] = true -- No
L["OptAlertDesc"] = "Alert when this target is alive"

--Button strings
L["Snooze"] = true

--Option strings
L["OptSnoozeTimeout"] = "Snooze button duration (minutes)"
L["OptSnoozeTimeoutDesc"] = "Don't alert for this long after snoozing"
L["OptSnoozeReset"] = "Clear snooze"
L["OptSnoozeResetDesc"] = "Re-enable alerts before snooze expires"
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
L["StateTimerSoon"] = 'About to start (%s)'
L["StateTimerTick"] = 'Started at %s'
L["StateTimerRunning"] = 'Next event at %s'

-- Mob names
L["Aggregor the Dust Eater"] = true
L["Bugwit"] = true
L["Critical Containment"] = true
L["Defensive Protocol Unit"] = true
L["Doomthorn the Ancient"] = true
L["Gargantua"] = true
L["Grendelus the Guardian"] = true
L["Grinder"] = true
L["Hoarding Stemdragon"] = true
L["KE-27 Sentinel"] = true
L["King Honeygrave"] = true
L["Kraggar the Earth-Render"] = true
L["Metal Maw"] = true
L["Metal Maw Prime"] = true
L["Scorchwing"] = true
L["Subject J - Fiend"] = true
L["Subject K - Brute"] = true
L["Subject Tau"] = true
L["Subject V - Tempest"] = true
L["Zoetic"] = true
L["Star-Comm Basin"] = true