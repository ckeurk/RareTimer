-- Thanks to Leosky for the proper translations. The butchered ones are my own. :D

local Locale = "frFR"
local IsDefaultLocale = false
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:NewLocale("RareTimer", Locale, IsDefaultLocale)
if not L then return end

L["LocaleName"] = Locale

--Heading strings
L["CmdListHeading"] = "RareTimer registre d'état:" 
L["AlertHeading"] = "Alerte de RareTimer:"
L["Name"] = "Nom"
L["Status"] = "Condition"
L["Last kill"] = "Tué"
L["Health"] = "Vie"

--Msgs
L["NewVersionMsg"] = "Une nouvelle version de RareTimer est disponible."
L["ObsoleteVersionMsg"] = "RareTimer n'est pas à jour et ne recevra plus de mises à jour d'autres clients."
L["SnoozeMsg"] = "RareTimer: N'alerter pas pour %s minutes."
L["SnoozeResetMsg"] = "RareTimer: Rappel d'alarme remise à zéro."
L["Y"] = "O" -- Yes
L["N"] = "N" -- No

--Button strings
L["Snooze"] = "Rappel"

--Option strings
L["OptSnoozeTimeout"] = "Durée du rappel d'alarme (minutes)"
L["OptSnoozeTimeoutDesc"] = "Durée pendant qu'on n'alerte pas apres rappel d'alarm."
L["OptSnoozeReset"] = "Remiser à zéro le rappel d'alarm"
L["OptSnoozeResetDesc"] = "Remiser à zéro le rappel d'alarm"
L["OptTargetTimeout"] = "N'alerter pas après avoir ciblé (minutes)"
L["OptTargetTimeoutDesc"] = "N'alerter pas si on a ciblé l'ennemi dans le délai."
L["OptPlaySound"] = "Faire sonner"
L["OptPlaySoundDesc"] = "Faire sonner lorsque l'alerte est déclencher."

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
L["StateTimerSoon"] = 'Bientôt (%s)'
L["StateTimerTick"] = 'Commencé à %s'
L["StateTimerRunning"] = 'Prochain à %s'
 
-- Mob names
L["Aggregor the Dust Eater"] = "Aggregor le Mâchepoussière"
L["Bugwit"] = "Bugwit"
L["Critical Containment"] = "Tissu d'horreurs"
L["Defensive Protocol Unit"] = "Unité de protocoles défensifs"
L["Doomthorn the Ancient"] = "Funestépine l'Ancien"
L["Gargantua"] = "Gargantua"
L["Grendelus the Guardian"] = "Gardien Grendelus"
L["Grinder"] = "Broyeur" 
L["Hoarding Stemdragon"] = "Plandragon avide"
L["KE-27 Sentinel"] = "Sentinelle KE-27"
L["King Honeygrave"] = "Roi Nectaruine"
L["Kraggar the Earth-Render"] = "Kraggar le Crève-terre"
L["Metal Maw"] = "Gueule d'acier"
L["Metal Maw Prime"] = "Primo Gueule d'acier"
L["Scorchwing"] = 'Ailardente'
L["Subject J - Fiend"] = "Sujet J : démon"
L["Subject K - Brute"] = "Sujet K : brute"
L["Subject Tau"] = "Sujet Tau"
L["Subject V - Tempest"] = "Sujet V : tempête"
L["Zoetic"] = "Zoetic"
L["Star-Comm Basin"] = "Star-Comm Basin"