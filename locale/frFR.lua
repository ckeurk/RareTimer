-- Thanks to Leosky for the proper translations. The butchered ones are my own. :D

local Locale = "frFR"
local IsDefaultLocale = false
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", Locale, IsDefaultLocale)
if not L then return end

L["LocaleName"] = Locale

--Heading strings
L["CmdListHeading"] = "RareTimer registre d\194\180 \195\169tat:" 
L["AlertHeading"] = "Alerte de RareTimer:"
L["Name"] = "Nom"
L["Status"] = "Condition"
L["Last kill"] = "Tu\195\169"
L["Health"] = "Vie"

--Msgs
L["NewVersionMsg"] = "Une nouvelle version de RareTimer est disponible."
L["ObsoleteVersionMsg"] = "RareTimer n'est pas \195\160 jour et ne recevra plus de mises \195\160 jour d'autres clients."
L["SnoozeMsg"] = "RareTimer: N'alerter pas pour %s minutes."
L["SnoozeResetMsg"] = "RareTimer: Rappel d'alarme remise \195\160 z\195\169ro."
L["Y"] = "O" -- Yes
L["N"] = "N" -- No

--Button strings
L["Snooze"] = "Rappel"

--Option strings
L["OptSnoozeTimeout"] = "Dur\195\169e du rappel d'alarme (minutes)"
L["OptSnoozeTimeoutDesc"] = "Dur\195\169e pendant qu'on n'alerte pas apres rappel d'alarm."
L["OptSnoozeReset"] = "Remise \195\160 z\195\169ro de l'alarme"
L["OptSnoozeResetDesc"] = "Remise \195\160 zèro de l'alarme"
L["OptTargetTimeout"] = "N'alerter pas apr\195\169s avoir cibl\195\169 (minutes)"
L["OptTargetTimeoutDesc"] = "N'alerter pas si vous avez cibl\195\169 l'ennemi dans le délai."
L["OptPlaySound"] = "Faire sonner"
L["OptPlaySoundDesc"] = "Faire sonner lorsque l'alerte est d\195\169clencher."

--Time strings
L["s"] = "s" -- Seconds
L["m"] = "m" -- Minutes
L["h"] = "h" -- Hours
L["d"] = "j" -- Days

-- State strings
L["StateUnknown"] = 'Inconnu'
L["StateKilled"] = 'Tu\195\169 ‡ %s'
L["StateDead"] = 'Tu\195\169 au plus tard ‡ %s'
L["StatePending"] = 'Devrait reparaitre avant %s'
L["StateAlive"] = 'En vie (%s)'
L["StateInCombat"] = 'En combat'
L["StateExpired"] = 'Inconnu (vu la derni\195\169re fois ‡ %s)'
L["StateTimerSoon"] = 'Bient\195\180t (%s)'
L["StateTimerTick"] = 'Commence dans %s'
L["StateTimerRunning"] = 'Prochain dans %s'
 
-- Mob names
L["Aggregor the Dust Eater"] = "Aggregor le M‚chepoussi\195\169re"
L["Bugwit"] = "Bugwit"
L["Critical Containment"] = "Tissu d'horreurs"
L["Defensive Protocol Unit"] = "Unit\195\169 de protocoles d\195\169fensifs"
L["Doomthorn the Ancient"] = "Funestépine l'Ancien"
L["Gargantua"] = "Gargantua"
L["Grendelus the Guardian"] = "Gardien Grendelus"
L["Grinder"] = "Broyeur" 
L["Hoarding Stemdragon"] = "Plandragon avide"
L["KE-27 Sentinel"] = "Sentinelle KE-27"
L["King Honeygrave"] = "Roi Nectaruine"
L["Kraggar the Earth-Render"] = "Kraggar le Cr\195\169ve-terre"
L["Metal Maw"] = "Gueule d'acier"
L["Metal Maw Prime"] = "Primo Gueule d'acier"
L["Scorchwing"] = 'Ailardente'
L["Subject J - Fiend"] = "Sujet J : démon"
L["Subject K - Brute"] = "Sujet K : brute"
L["Subject Tau"] = "Sujet Tau"
L["Subject V - Tempest"] = "Sujet V : tempÍte"
L["Zoetic"] = "Zoetic"
L["Star-Comm Basin"] = "Star-Comm Basin"
