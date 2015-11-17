-----------------------------------------------------------------------------------------------
-- Client Lua Script for RareTimer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
require "math"
require "string"
require "GameLib"
require "ICCommLib"
require "ICComm"

-----------------------------------------------------------------------------------------------
-- Local caching
-----------------------------------------------------------------------------------------------
local string = string
local math = math
local GameLib = GameLib
local ICCommLib = ICCommLib
local LibJSON
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local MAJOR, MINOR = "RareTimer-2.1", 0
local DEBUG = false -- Debug mode
local NONET = false -- Block send/receive data
local CONFIGWIDTH = 335
local CONFIGHEIGHT = 740

-- Apollo strings
kStringOk = 3

-- Data sources
local Source = {
  Target = 0,
  Kill = 1,
  Create = 2,
  Destroy = 3,
  Combat = 4,
  Report = 5,
  Timer = 6,
  Corpse = 7,
}

-- Mob entry states
local States = {
  Unknown = 0, -- Unseen, unreported
  Killed = 1, -- Player saw kill
  Dead = 2, -- Player saw corpse, but not the kill
  Pending = 3, -- Should spawn anytime now
  Alive = 4, -- Up and at full health
  InCombat = 5, -- In combat (not at 100%)
  Expired = 6, -- Been longer than MaxSpawn since last known kill
  TimerSoon = 7, -- Timer about to ding
  TimerTick = 8, -- Timer completed a cycle
  TimerRunning = 9, -- Timer in the middle of a cycle
}

-- Header for broadcast messages
local MsgHeader = {
  MsgVersion = 3, -- Increment when format of broadcast data changes
  Required = 3, -- Set to MsgVersion when format changes and breaks backwards compatibility
  RTVersion = {Major = MAJOR, Minor = MINOR},
}
 
-- Broadcast message types
local MsgTypes = {
  Update = 0,
  Sync = 1,
  New = 2,
}

-- What we know about the spawn time
local SpawnTypes = {
  Other = 0,
  Window = 1,
  Timer = 2,
}

-- What type of thing are we tracking
local AlertTypes = {
  Mob = 0,
  Event = 1,
}

-- Event spawn times
local Times = {
  Midnight = {
    nHour = 0,
    nMinute = 0,
    nSecond = 0,
  },
  Offset1 = {
    nHour = 1,
    nMinute = 0,
    nSecond = 0
  }
}

-----------------------------------------------------------------------------------------------
-- RareTimer Module Definition
-----------------------------------------------------------------------------------------------
local RareTimer = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon(MAJOR, false) -- Configure = false
local GeminiConfig = Apollo.GetPackage("Gemini:Config-1.0").tPackage
local ConfigDialog = Apollo.GetPackage("Gemini:ConfigDialog-1.0").tPackage
local GeminiGUI = Apollo.GetPackage("Gemini:GUI-1.0").tPackage
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("RareTimer", true) -- Silent = true
local Optparse = Apollo.GetPackage("Optparse-0.3").tPackage

-----------------------------------------------------------------------------------------------
-- Config/DB init
-----------------------------------------------------------------------------------------------
local confPosition = 0

function nextPos()
  confPosition = confPosition + 10
  return confPosition
end

local optionsTable = {
    type = "group",
    args = {
        settingsheader = {
            name = L["OptSettingsHeader"],
            type = "header",
            order = nextPos(),
        },
        targettimeout = {
            name = L["OptTargetTimeout"],
            desc = L["OptTargetTimeoutDesc"],
            type = "input",
            order = nextPos(),
            validate = function(info, val) 
                local num = tonumber(val)
                return num ~= nil and num > 0 and num <= 30 and math.floor(num) == num
            end,
            set = function(info, val) RareTimer.db.profile.config.LastTargetTimeout = tonumber(val) * 60 end,
            get = function(info) return tostring(math.floor(RareTimer.db.profile.config.LastTargetTimeout / 60)) end,
        },
        playsound = {
            name = L["OptPlaySound"],
            desc = L["OptPlaySoundDesc"],
            type = "toggle",
            order = nextPos(),
            set = function(info, val) RareTimer.db.profile.config.PlaySound = val end,
            get = function(info) return RareTimer.db.profile.config.PlaySound end,
        },

        snoozeheader = {
            name = L["OptSnoozeHeader"],
            type = "header",
            order = nextPos(),
        },
        snoozetimeout = {
            name = L["OptSnoozeTimeout"],
            desc = L["OptSnoozeTimeoutDesc"],
            type = "input",
            order = nextPos(),
            validate = function(info, val) 
                local num = tonumber(val)
                return num ~= nil and num > 0 and num <= 480 and math.floor(num) == num
            end,
            set = function(info, val) 
                RareTimer.db.profile.config.SnoozeTimeout = tonumber(val) * 60 
                RareTimer:UpdateSnoozeTimer()
            end,
            get = function(info) return tostring(math.floor(RareTimer.db.profile.config.SnoozeTimeout / 60)) end,
        },
        snoozereset = {
            name = L["OptSnoozeReset"],
            desc = L["OptSnoozeResetDesc"],
            type = "execute",
            order = nextPos(),
            func = function() 
                RareTimer.db.char.LastSnooze = nil 
                RareTimer:UpdateSnoozeTimer()
                RareTimer.CPrint(RareTimer, L["SnoozeResetMsg"])
            end,
        },

        alerts = {
            name = L["OptAlertsHeader"],
            type = "header",
            order = nextPos(),
        },
        -- Remaining widgits added by RareTimer:AddEntriesToConfig()
    }
}

local defaults = {
    profile = {
        config = {
            PlaySound = true,
            Slack = 600, --10m, MaxSpawn + Slack = Expired
            CombatTimeout = 300, -- 5m, leave combat state after no updates within this time
            ReportTimeout = 300, -- 5m, don't send basic sync broadcasts if we saw a report within this time
            SnoozeTimeout = 1800, -- 30m, snooze button suppresses alerts for this period
            UnknownTimeout = 3600, -- 1h, state changes to unknown if older, if MaxSpawn is undefined
            EventTimeout = 600, -- 10m, if event started before this time, go to running state
            LastTargetTimeout = 120, -- 2m, If we targeted the mob within this time, don't alert
            NewerThreshold = 30, -- 0.5m, ignore reports unless they are at least this much newer
            WarnAhead = 600, -- 10m, send alert in advance by this much (for timer based alerts)
            Track = {
                L["Aggregor the Dust Eater"],
                L["Bugwit"],
                L["Critical Containment"],
                L["Defensive Protocol Unit"],
                L["Doomthorn the Ancient"],
                L["Gargantua"],
                L["Grendelus the Guardian"],
                L["Grinder"], -- Note: Shares name with npc in Thayd
                L["Hoarding Stemdragon"],
                L["KE-27 Sentinel"],
                L["King Honeygrave"],
                L["Kraggar the Earth-Render"],
                L["Metal Maw"],
                L["Metal Maw Prime"],
                L["Scorchwing"],
                L["Subject J - Fiend"],
                L["Subject K - Brute"],
                L["Subject Tau"],
                L["Subject V - Tempest"],
                L["Zoetic"],
                L["Star-Comm Basin"]
            }
        },
    },
    char = {
        LastSnooze = nil,
    },
    realm = {
        LastBroadcast = nil,
        mobs = {
            ['**'] = {
                --Name
                State = States.Unknown,
                --Killed
                --Timestamp
                --MinSpawn
                --MaxSpawn
                SpawnType = SpawnTypes.Other,
                AlertType = AlertTypes.Mob,
                --MinDue
                --MaxDue
                --Expires
                --LastReport
                --LastBroadcast
                --LastTarget
                AlertOn = true,
                --TickStart
                --TickInterval
                --LastTick
                --NextTick
            },
            {    
                Name = L["Scorchwing"],
                MinSpawn = 3600, --60m
                MaxSpawn = 6600, --110m
                SpawnType = SpawnTypes.Window,
            },
            {
                Name = L["Bugwit"],
                AlertOn = false,
            },
            {
                Name = L["Grinder"],
                AlertOn = false,
            },
            {
                Name = L["KE-27 Sentinel"],
                AlertOn = false,
            },
            {
                Name = L["Subject J - Fiend"],
                AlertOn = false,
            },
            {
                Name = L["Subject K - Brute"],
                AlertOn = false,
            },
            {
                Name = L["Subject Tau"],
                AlertOn = false,
            },
            {
                Name = L["Subject V - Tempest"],
                AlertOn = false,
            },
            {
                Name = L["Aggregor the Dust Eater"],
                AlertOn = false,
            },
            {
                Name = L["Defensive Protocol Unit"],
                AlertOn = false,
            },
            {
                Name = L["Doomthorn the Ancient"],
                AlertOn = false,
            },
            {
                Name = L["Grendelus the Guardian"],
                AlertOn = false,
            },
            {
                Name = L["Hoarding Stemdragon"],
                AlertOn = false,
            },
            {
                Name = L["King Honeygrave"],
                AlertOn = false,
            },
            {
                Name = L["Kraggar the Earth-Render"],
                AlertOn = false,
            },
            {
                Name = L["Metal Maw"],
                AlertOn = false,
            },
            {
                Name = L["Metal Maw Prime"],
                AlertOn = false,
            },
            {
                Name = L["Zoetic"],
                AlertOn = false,
            },
            {
                Name = L["Critical Containment"],
                AlertType = AlertTypes.Event,
                SpawnType = SpawnTypes.Timer,
                TickStart = Times.Midnight,
                TickInterval = 14400, -- 4h
            },
            {
                Name = L["Gargantua"],
                AlertOn = false,
            },
            {    
                Name = L["Star-Comm Basin"],
                AlertType = AlertTypes.Event,
                SpawnType = SpawnTypes.Timer,
                TickStart = Times.Offset1,
                TickInterval = 7200, -- 2h
            },
        }
    }
}

-----------------------------------------------------------------------------------------------
-- RareTimer OnInitialize
-----------------------------------------------------------------------------------------------
function RareTimer:OnInitialize()
    -- Init db
    self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, defaults, true)
    LibJSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage

    -- Done init
    self.IsLoading = false
end

-----------------------------------------------------------------------------------------------
-- RareTimer OnEnable
-----------------------------------------------------------------------------------------------
function RareTimer:OnEnable()
    -- Slash commands
    Apollo.RegisterSlashCommand("raretimer", "OnRareTimerOn", self)
    self.opt = Optparse:OptionParser{usage="%prog [options]", command="raretimer"}
    if DEBUG then
        SendVarToRover("OptionParser", self.opt)
    end
    self:AddOptions()

    -- Event handlers
    Apollo.RegisterEventHandler("CombatLogDamage", "OnCombatLogDamage", self)
    Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
    Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
    Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
    Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)
    Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
    Apollo.RegisterEventHandler("ToggleRareTimer", "OnToggleRareTimer", self)

    if DEBUG then
        Apollo.RegisterEventHandler("ICCommReceiveThrottled", "OnICCommReceiveThrottled", self)
    end

    -- Status update channel
    self.channel = ICCommLib.JoinChannel("RareTimerChannel", ICCommLib.CodeEnumICCommChannelType.Global)
    self.channel:SetReceivedMessageFunction("OnRareTimerChannelMessage", self);

    -- Timers
    self.timer = ApolloTimer.Create(30.0, true, "OnTimer", self) -- In seconds
    if DEBUG then
        SendVarToRover("Mob Entries", self.db.realm.mobs)
    end

    -- Init config
    self:AddEntriesToConfig()
    GeminiConfig:RegisterOptionsTable("RareTimer", optionsTable)
	ConfigDialog:SetDefaultSize("RareTimer", CONFIGWIDTH, CONFIGHEIGHT)

    -- Window
    self.wndMain = self:InitMainWindow()
    self.wndMain:Show(false)
end

-----------------------------------------------------------------------------------------------
-- Slash commands
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/raretimer"
function RareTimer:OnRareTimerOn(sCmd, sInput)
    local s = string.lower(sInput)
    local options, args = self.opt.parse_args(sInput)
    if DEBUG then
        SendVarToRover("Options", options)
        SendVarToRover("Args", args)
    end
    if options ~= nil then
        if options.list then
            self:CmdList(s)
        elseif options.say then
            self:CmdSpam(s)
        elseif options.debug then
            self:PrintTable(self:GetEntries())
        elseif options.debugconfig then
            self:PrintTable(self.db.profile.config)
            self:PrintTable(self.db.char)
        elseif options.show then
            self.wndMain:Show(true)
        elseif options.hide then
            self.wndMain:Show(false)
        elseif options.toggle then
            self.wndMain:Show(not self.wndMain:IsVisible())
        elseif options.reset then
            self:CPrint("Resetting RareTimer db")
            self.db:ResetProfile()
            self.db:ResetDB()
        elseif options.config then
            ConfigDialog:Open("RareTimer")
        elseif options.test then
            --[[
            local now = GameLib.GetServerTime()
            local entry = {    
                State = States.Unknown,
                Name = "Testy McTestMob",
                MinSpawn = 120, --2m
                MaxSpawn = 600, --10m
                Timestamp = now,
            }

            self:SendState(entry, nil, true)
            --]]
        else
            self.opt.print_help()
        end
    end
end

function RareTimer:AddOptions()
    self.opt.add_option{'-l', '--list', action='store_true', dest='list', help='List mobs'}
    self.opt.add_option{'-S', '--say', action='store', dest='say', help='Say mob status'}
    self.opt.add_option{'-c', '--channel', action='store', dest='channel', help='Channel to use for --say', default="p"}
    self.opt.add_option{'-C', '--config', action='store_true', dest='config', help='Open configuration window'}
    self.opt.add_option{'-d', '--debug', action='store_true', dest='debug', help='debug mobs'}
    self.opt.add_option{'-D', '--debugconfig', action='store_true', dest='debugconfig', help='debug config'}
    self.opt.add_option{'-s', '--show', action='store_true', dest='show', help='Show window'}
    self.opt.add_option{'-H', '--hide', action='store_true', dest='hide', help='Hide window'}
    self.opt.add_option{'-t', '--toggle', action='store_true', dest='toggle', help='Toggle window'}
    self.opt.add_option{'-r', '--reset', action='store_true', dest='reset', help='Reset all settings/stored data'}
    self.opt.add_option{'-T', '--test', action='store_true', dest='test', help='Test command'}
end

-----------------------------------------------------------------------------------------------
-- Event handlers
-----------------------------------------------------------------------------------------------

-- Capture mobs as they're targeted
function RareTimer:OnTargetUnitChanged(unit)
    self:UpdateEntry(unit, Source.Target)
end

-- Capture mobs as they're killed/damaged
function RareTimer:OnCombatLogDamage(tEventArgs)
    if tEventArgs.bTargetKilled then
        self:UpdateEntry(tEventArgs.unitTarget, Source.Kill)
    else
        self:UpdateEntry(tEventArgs.unitTarget, Source.Combat)
    end
end

-- Capture mobs as they enter combat
function RareTimer:OnUnitEnteredCombat(unit, bInCombat)
    self:UpdateEntry(unit, Source.Combat)
end

-- Capture newly loaded/spawned mobs
function RareTimer:OnUnitCreated(unit)
    self:UpdateEntry(unit, Source.Create)
end

-- Capture mobs as they despawn
function RareTimer:OnUnitDestroyed(unit)
    self:UpdateEntry(unit, Source.Destroy)
end

-- Detect if we're loading a new map (and various things are unavailable)
function RareTimer:OnChangeWorld()
    self.IsLoading = true
    self.timer:Stop()
    if self.LoadingTimer == nil then
        self.LoadingTimer = ApolloTimer.Create(1, true, "OnLoadingTimer", self) -- In seconds
    else
        self.LoadingTimer:Start()
    end
end

-- Check if we're done loading
function RareTimer:OnLoadingTimer()
    if IsLoading == false or GameLib.GetPlayerUnit() ~= nil then
        self.IsLoading = false
        self.LoadingTimer:Stop()
        self.timer:Start()
    end
end

-- Trigger housekeeping/announcements
function RareTimer:OnTimer()
    self:UpdateState()
    self:BroadcastDB()
end

-- Parse announcements from other clients
function RareTimer:OnRareTimerChannelMessage(channel, msgStr, idMessage)
    if DEBUG then
        SendVarToRover('Received Msg', msgStr)
    end
    self:ReceiveData(msgStr, idMessage)
end

-- Register the window with Wildstar's window management
function RareTimer:OnWindowManagementReady()
    Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMain, strName = "RareTimer" })
end

-- Add us to the interface menu
function RareTimer:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "RareTimer", 
		{"ToggleRareTimer", "", "CRB_Basekit:kitIcon_Holo_Clock"})
end

-- Toggle the window when clicked in the interface menu
function RareTimer:OnToggleRareTimer()
    if self.wndMain ~= nil then
        self.wndMain:Show(not self.wndMain:IsVisible())
    end
end

-- Report on throttled messages
function RareTimer:OnICCommReceiveThrottled(channel, name)
    self:CPrint(string.format("Message throttled on %s from %s", channel, name))
end
-----------------------------------------------------------------------------------------------
-- RareTimer Functions
-----------------------------------------------------------------------------------------------

-- Update the status of a rare mob
function RareTimer:UpdateEntry(unit, source)
    if self:IsMob(unit) and self:IsNotable(unit:GetName()) then
        local entry = self:GetEntry(unit:GetName())
        if source == Source.Target then
            local now = GameLib.GetServerTime()
            entry.LastTarget = now
        end
        if unit:IsDead() then
            if source == Source.Kill then
                self:SawKilled(entry, source)
            else
                self:SawDead(entry, source)
            end
        else
            self:SetHealth(entry, self:GetUnitHealth(unit))
            self:SawAlive(entry, source)
        end
    end
end

-- Record a kill
function RareTimer:SawKilled(entry, source)
    if entry ~= nil then
        self:SetState(entry, States.Killed, Source.Kill)
        self:SetKilled(entry)
        self:UpdateDue(entry)
    end
end

-- Record a corpse
function RareTimer:SawDead(entry, source)
    if entry ~= nil and entry.State ~= States.Killed and entry.State ~= States.Dead then
        self:SetState(entry, States.Dead, Source.Corpse)
        self:SetKilled(entry)
        self:UpdateDue(entry)
    end
end

-- Record a live mob
function RareTimer:SawAlive(entry, source)
    local alert = false
    if entry.Health ~= nil and entry ~= nil then
        if entry.Health == 100 then
            if entry.State ~= States.Alive then
                alert = true
            end
            self:SetState(entry, States.Alive, Source.Combat)
        else
            if entry.State ~= States.InCombat then
                alert = true
            end
            self:SetState(entry, States.InCombat, Source.Combat)
        end
    end

    if alert then
        self:Alert(entry)
    end
end

-- Calculate % mob health
function RareTimer:GetUnitHealth(unit)
    if unit ~= nil then
        local health = unit:GetHealth()
        local maxhealth = unit:GetMaxHealth()
        if health ~= nil and maxhealth ~= nil then
            assert(type(health) == "number", "GetHealth returned invalid number")
            assert(type(maxhealth) == "number", "GetMaxHealth returned invalid number")
            if maxhealth > 0 then
                return math.floor(health / maxhealth * 100)
            end
        end
    end
end

-- Is this a mob we are interested in?
function RareTimer:IsNotable(name)
    if name == nil or name == '' then
        return false
    end
    for _, value in pairs(self.db.profile.config.Track) do
        if value == name then
            return true
        end
    end
    return false
end

-- Is this a mob?
function RareTimer:IsMob(unit)
    if unit ~= nil and unit:IsValid() and unit:GetType() == 'NonPlayer' then
        return true
    else
        return false
    end
end

-- Spam status of a given mob to a channel
function RareTimer:CmdSpam(input)
    --Guild/zone/party
    --Spam health if alive, last death if dead
    self:CPrint("Not yet implemented")
end

-- Print status list
function RareTimer:CmdList(input)
    self:CPrint(L["CmdListHeading"])
    for _, mob in pairs(self:GetEntries()) do
        local statusStr = string.format("%s: %s", mob.Name, self:GetStatusStr(mob))
        if statusStr ~= nil then
            self:CPrint(statusStr)
        end
    end
end

-- Generate a status string for a given entry
function RareTimer:GetStatusStr(entry)
    if entry.Name == nil then
        return nil
    end

    local when
    local strState = 'ERROR'
    if entry.State == States.Unknown or (entry.State == States.Expired and entry.Timestamp == nil) then
        strState = L["StateUnknown"]
    elseif entry.State == States.Killed then
        strState = L["StateKilled"]
        when = entry.Killed
    elseif entry.State == States.Dead then
        strState = L["StateDead"]
        when = entry.Killed
    elseif entry.State == States.Pending then
        strState = L["StatePending"]
        when = entry.MaxDue
    elseif entry.State == States.Alive then
        strState = L["StateAlive"]
        when = entry.Timestamp
    elseif entry.State == States.InCombat then
        strState = L["StateInCombat"]
        when = entry.Timestamp
    elseif entry.State == States.Expired then
        strState = L["StateExpired"]
        when = entry.Timestamp
    elseif entry.State == States.TimerSoon then
        strState = L["StateTimerSoon"]
        when = entry.NextTick
    elseif entry.State == States.TimerTick then
        strState = L["StateTimerTick"]
        when = entry.LastTick
    elseif entry.State == States.TimerRunning then
        strState = L["StateTimerRunning"]
        when = entry.NextTick
    end

    if when ~= nil then
        return string.format(strState, self:FormatDate(self:LocalTime(when)))
    else
        return strState
    end
end

-- Convert a date to a string in the format YYYY-MM-DD hh:mm:ss pp
function RareTimer:FormatDate(date)
    return string.format('%d-%02d-%02d %s', date.nYear, date.nMonth, date.nDay, date.strFormattedTime)
end

-- Get the db entry for a mob
function RareTimer:GetEntry(name)
    for _, mob in pairs(self:GetEntries()) do
        if mob.Name == name then
            return mob
        end
    end
end

-- Print to the Command channel
function RareTimer:CPrint(msg)
    if msg == nil then
        return
    end

    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, msg, "")
end

-- Print the contents of a table to the Command channel
function RareTimer:PrintTable(table, depth)
    if table == nil then
        Print("Nil table")
        return
    end
    if depth == nil then
        depth = 0
    end
    if depth > 10 then
        return
    end

    local indent = string.rep(' ', depth*2)
    for name, value in pairs(table) do
        if type(value) == 'table' then
            if value.strFormattedTime ~= nil then
                local strTimestamp = self:FormatDate(value)
                self:CPrint(string.format("%s%s: %s", indent, name, strTimestamp))
            else
                self:CPrint(string.format("%s%s: {", indent, name))
                self:PrintTable(value, depth + 1)
                self:CPrint(string.format("%s}", indent))
            end
        else
            self:CPrint(string.format("%s%s: %s", indent, name, tostring(value)))
        end
    end
end    

-- Make a copy (i.e. of a table) that shares no resources with the original
-- From http://lua-users.org/wiki/CopyTable
function RareTimer:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


-- Make a copy of t2 but overwritten with any values present in t1
function RareTimer:TableMerge(t2, t1)
    local merged = self:DeepCopy(t2)
    for key, value in pairs(t1) do
        merged[key] = value
    end
    return merged
end

-- Progress state (expire entries, etc.)
function RareTimer:UpdateState()
    for _, mob in pairs(self:GetEntries()) do
        if mob.SpawnType == SpawnTypes.Timer then
            self:UpdateTicks(mob)
            if self:IsDue(mob) then
                self:SetState(mob, States.TimerSoon, Source.Timer)
            elseif not self:IsExpired(mob) then
                self:SetState(mob, States.TimerTick, Source.Timer)
            else
                self:SetState(mob, States.TimerRunning, Source.Timer)
            end
        -- Expire entries
        elseif mob.State ~= States.Unknown and mob.State ~= States.Expired and self:IsExpired(mob) then
            self:SetState(mob, States.Expired, Source.Timer)
        elseif mob.State == States.InCombat and self:IsCombatExpired(mob) then
            self:SetState(mob, States.Expired, Source.Timer)
        -- Set pending spawn
        elseif mob.SpawnType == SpawnTypes.Window and mob.State ~= States.Pending and self:IsDue(mob) then
            self:SetState(mob, States.Pending, Source.Timer)
        end
    end
end

-- Check if an entry is due to spawn
function RareTimer:IsDue(entry)
    -- If it's an event, check if it's about to start
    if entry.SpawnType == SpawnTypes.Timer then
        local now = GameLib.GetServerTime()
        if entry.NextTick ~= nil and self:DiffTime(entry.NextTick, now) < self.db.profile.config.WarnAhead then
            return true
        else
            return false
        end
    -- If it's a mob, check if it's about to spawn
    else
        -- If we can't predict a time, return false
        local killedAgo = self:GetAge(entry.Killed)
        if entry.MinSpawn == nil or entry.MaxSpawn == nil or entry.MaxDue == nil or entry.killedAgo == nil then
            return false
        end

        -- Move the due time up if we only saw the corpse, not the kill
        local due = entry.MinSpawn
        if entry.State == States.Dead then
            due = due - self.db.profile.config.Slack
        end

        -- Check if enough time has passed that it could spawn
        if (entry.State == States.Killed or entry.State == States.Dead) and killedAgo > due then
            return true
        else
            return false
        end
    end
end

-- Check if an entry is expired
function RareTimer:IsExpired(entry)
    -- If it's an event, check if it started recently
    if entry.SpawnType == SpawnTypes.Timer then
        if entry.LastTick == nil or self:GetAge(entry.LastTick) > self.db.profile.config.EventTimeout then
            return true
        else
            return false
        end
    -- If it's a mob, check if it has been too long since we heard about it
    else
        -- If we don't know when it's due to spawn, treat it as expired
        if entry.State == States.Pending and entry.MaxDue == nil then
            return true
        end

        -- If we know min/max spawn times, use those, otherwise UnknownTimeout
        local ago = self:GetAge(entry.Timestamp)
        local maxAge
        if entry.SpawnType == SpawnTypes.Window then
            maxAge = entry.MaxSpawn + self.db.profile.config.Slack
        else
            maxAge = self.db.profile.config.UnknownTimeout
        end

        -- Check if it has timed out
        if (ago ~= nil and ago > maxAge) then
            return true
        else
            return false
        end
    end
end

-- Update last and next event times
function RareTimer:UpdateTicks(entry)
    local now = GameLib.GetServerTime()
    local tick = self:TableMerge(now, entry.TickStart) -- E.g. the preceeding midnight
    while self:DiffTime(now, tick) > entry.TickInterval do
        tick = self:AddDur(tick, entry.TickInterval)
    end
    entry.LastTick = tick
    entry.NextTick = self:AddDur(tick, entry.TickInterval)
end

-- Check if an entry is past the combat expiration time
function RareTimer:IsCombatExpired(entry)
    local ago = self:GetAge(entry.Timestamp)
    if ago ~= nil and ago > self.db.profile.config.CombatTimeout then
        return true
    else
        return false
    end
end

-- Get the age in seconds
function RareTimer:GetAge(timestamp)
    if timestamp ~= nil then
        local now = GameLib.GetServerTime()
        return self:DiffTime(now, timestamp)
    else
        return nil
    end
end

-- Set the entry's state
function RareTimer:SetState(entry, state, source)
    local now = GameLib.GetServerTime()
    if entry.State ~= state then
        entry.State = state
        entry.Timestamp = now
        entry.Source = source
        if entry.SpawnType == SpawnTypes.Timer and state == States.TimerSoon then
            self:Alert(entry)
        end
    end
    if (state ~= States.Alive and state ~= States.InCombat) then
        self:SetHealth(entry, nil)
    end
end

-- Set the entry's last kill time
function RareTimer:SetKilled(entry, time)
    if time == nil then
        time = GameLib.GetServerTime()
    end
    entry.Killed = time
end

-- Set the entry's health
function RareTimer:SetHealth(entry, health)
    entry.Health = health
end

-- Set the estimated spawn window
function RareTimer:UpdateDue(entry)
        local adjust
        if entry.State == States.Dead then
            adjust = self.db.profile.config.Slack
        else
            adjust = 0
        end

        if entry.MinSpawn ~= nil and entry.MinSpawn > 0 then
            entry.MinDue = self:ToWsTime(self:ToLuaTime(entry.Killed) + entry.MinSpawn - adjust)
        else
            entry.MinDue = nil
        end
        if entry.MaxSpawn ~= nil and entry.MaxSpawn > 0 then
            entry.MaxDue = self:ToWsTime(self:ToLuaTime(entry.Killed) + entry.MaxSpawn)
        else
            entry.MaxDue = nil
        end
end

-- Convert Wildstar time to lua time
function RareTimer:ToLuaTime(wsTime)
    if wsTime == nil then
        return
    end
    local convert = {
        year = wsTime.nYear,
        month = wsTime.nMonth,
        day = wsTime.nDay,
        hour = wsTime.nHour,
        min = wsTime.nMinute,
        sec = wsTime.nSecond
    }
    return os.time(convert)
end

-- Convert lua time to Wildstar time
function RareTimer:ToWsTime(luaTime)
    local date = os.date('*t', luaTime)
    local convert = {
        nYear = date.year,
        nMonth = date.month,
        nDay = date.day,
        nHour = date.hour,
        nMinute = date.min,
        nSecond = date.sec,
        strFormattedTime = os.date('%I:%M:%S %p', luaTime)
    }
    return convert
end

-- Measure difference between two times (in seconds)
function RareTimer:DiffTime(wsT2, wsT1)
    local t1 = self:ToLuaTime(wsT1)
    local t2 = self:ToLuaTime(wsT2)

    return os.difftime(t2, t1)
end

-- Is time T2 newer than time T1?
function RareTimer:IsNewer(wsT2, wsT1)
    if wsT2 == nil or wsT1 == nil then
        return true
    end
    return self:DiffTime(wsT2, wsT1) > self.db.profile.config.NewerThreshold
end

-- Convert a duration in seconds to a shortform string
function RareTimer:DurToStr(dur)
    if dur == nil then
        return
    end

    local min = 0
    local hour = 0
    local day = 0

    if dur > 59 then
        dur = math.floor(dur/60) 
        min = dur % 60
        if dur > 59 then
            dur = math.floor(dur/60) 
            hour = dur % 60
            if dur > 23 then
                day = dur % 24
            end
        end
    end

    local strOutput = ''
    if hour > 0 then
        strOutput = string.format("%02d%s", min, L["m"])
    else
        strOutput = string.format("%d%s", min, L["m"])
    end
    if hour > 0 then
        strOutput = string.format("%d%s", hour, L["h"]) .. strOutput
    end
    if day > 0 then
        strOutput = string.format("%d%s", day, L["d"]) .. strOutput
    end
    return strOutput
end

-- Adds a duration to a timestamp, i.e. gets a timestamp dur seconds after ts
function RareTimer:AddDur(ts, dur)
    local t = self:ToLuaTime(ts, true) + dur
    return self:ToWsTime(t)
end

-- Send contents of DB to other clients (if needed)
function RareTimer:BroadcastDB(test)
    if test == nil then
        test = false
    end

    local now = GameLib.GetServerTime()
    self.db.realm.LastBroadcast = now
    for _, entry in pairs(self:GetEntries()) do
        if self:ShouldBroadcast(entry) then
            if test then
                self:SendState(entry, nil, test)
            else
                self:SendState(entry)
            end
        end
    end
end

-- Check if we should broadcast the entry or not
function RareTimer:ShouldBroadcast(entry)
    local now = GameLib.GetServerTime()

    -- Don't broadcast fixed timer spawns
    if entry.SpawnType == SpawnTypes.Timer or entry.Timestamp == nil then 
        return false
    end

    -- If we have new info, send it out every ReportTimeout
    if entry.Source ~= Source.Report and entry.State ~= States.Expired and (entry.LastBroadcast == nil or self:DiffTime(now, entry.LastBroadcast) > self.db.profile.config.ReportTimeout) then
        return true
    end

    -- If we haven't received an update in awhile, send out whatever we have
    if entry.LastReport == nil or self:DiffTime(now, entry.LastReport) > self.db.profile.config.ReportTimeout then
        return true
    end

    return false
end

-- Format & broadcast an entry
function RareTimer:SendState(entry, msgtype, test)
    if test == nil then
        test = false
    end

    if msgtype == nil then
        msgtype = MsgTypes.Sync
    end

    local msg = {
        Type = msgtype,
        Name = self:DeLocale(entry.Name), -- Use english so we can communicate with other locales
        State = entry.State,
        Health = entry.Health,
        Killed = entry.Killed,
        Timestamp = entry.Timestamp,
        Source = entry.Source,
    }

    if test then
        self:SendTestData(msg)
    else
        self:SendData(msg)
    end

    local now = GameLib.GetServerTime()
    entry.LastBroadcast = now
end

-- Send data to other clients
function RareTimer:SendData(data, test)
    if test == nil then
        test = false
    end

    local msg = {}
    -- If we're given a string, encapsulate it in a table
    if type(data) ~= 'table' then
        msg.Data = {strMsg = msg}
    else
        msg.Data = data
    end

    -- Set header fields
    msg.Header = MsgHeader
    msg.Header.Timestamp = GameLib.GetServerTime()
    msg.Header.Locale = L["LocaleName"]

    -- Serialize
    local msgStr = LibJSON.encode(msg)

    if DEBUG then
        SendVarToRover("Sent Data", msgStr)
    end

    if NONET then
        return
    end

    -- If a test message, don't actually broadcast
    if test then
        self:OnRareTimerChannelMessage(self.channel, msgStr, "TestMsg")
    else
        self.channel:SendMessage(msgStr)
    end
end

-- "Send" data to ourself
function RareTimer:SendTestData(msg)
    self:SendData(msg, true)
end

-- Parse data from other clients
function RareTimer:ReceiveData(msgStr, idMessage)
    if DEBUG then
        SendVarToRover("Received Data", msgStr)
    end

    if NONET then
        return
    end

    -- Deserialize
    local msg = LibJSON.decode(msgStr)

    if msg == nil then
        if DEBUG then
            SendVarToRover("Nil message from", idMessage)
        end
        return
    end

    if msg.Header ~= nil then
        msg.Header.idMessage = idMessage
    else
        msg.Header = {idMessage = idMessage}
    end

    if self:ValidHeader(msg) then
        if msg.Header.Required > MsgHeader.MsgVersion then
            self:OutOfDate()
            return
        end
        if msg.Header ~= nil and msg.Header.RTVersion.Minor > MINOR then
            self:UpdateAvailable()
        end
    else
        if DEBUG then
            SendVarToRover("Invalid header", msg)
        end
        return
    end

    if not self:ValidData(msg) then
        if DEBUG then
            SendVarToRover("Invalid msg", msg)
        end
        return
    end

    --Parse msg
    local data = msg.Data
    local name = L[data.Name]
    if not self:IsNotable(name) then
        if DEBUG then
            SendVarToRover("Invalid name received", data.Name)
        end
        return
    end

    if msg.Header.idMessage == "TestMsg" then
        return
    end

    local entry = self:GetEntry(name)
    local now = GameLib.GetServerTime()
    local alert = false
    entry.LastReport = now
    if self:IsNewer(data.Timestamp, entry.Timestamp) then
        if entry.State ~= data.State and (data.State == States.Alive or data.State == States.InCombat or data.State == States.Killed) then
            alert = true
        end
        entry.State = data.State
        entry.Health = data.Health
        if data.Killed ~= nil and (entry.Killed == nil or self:IsNewer(data.Killed, entry.Killed)) then
            entry.Killed = data.Killed
        end
        entry.Timestamp = data.Timestamp
        entry.Source = Source.Report
    end

    if alert then
        self:Alert(entry)
    end
end

-- Verify format of msg
function RareTimer:ValidData(msg)
    if msg.Header ~= nil and msg.Data ~= nil and msg.Data.Name ~= nil and msg.Data.Timestamp ~= nil then
        return true
    else
        return false
    end
end

-- Verify format of header
function RareTimer:ValidHeader(msg)
    if msg ~= nil and msg.Header ~= nil and msg.Header.MsgVersion ~= nil and msg.Header.Required ~= nil and msg.Header.RTVersion ~= nil then
        return true
    else
        return false
    end
end

-- Inform user that a new version is available but not backwards compatible
function RareTimer:OutOfDate()
    if self.Outdated == nil then
        self:CPrint(L["ObsoleteVersionMsg"])
        self.Outdated = true
    end
end

-- Inform user that a newer version is available to download
function RareTimer:UpdateAvailable()
    if self.Updatable == nil then
        self:CPrint(L["NewVersionMsg"])
        self.Updatable = true
    end
end

-- Convert server time to local time
function RareTimer:LocalTime(date)
    local serverTime = self:ToLuaTime(date)
    local localTime = serverTime + self:GetTZOffset()
    return self:ToWsTime(localTime)
end

-- Calculate the offset between server time and local time
function RareTimer:GetTZOffset()
    return self:DiffTime(GameLib.GetLocalTime(), GameLib.GetServerTime())
end

-- Get the list of mob entries
function RareTimer:GetEntries()
    local entries = {}
    for _, entry in pairs(self.db.realm.mobs) do
        if entry.Name ~= nil and entry.Name ~= '' then
            table.insert(entries, entry)
        end
    end
    return entries
end

-- De-localize a string
function RareTimer:DeLocale(str)
    for key, value in pairs(L) do
        if str == value then
            return key
        end
    end
end

--Send an alert
function RareTimer:Alert(entry)
    if not entry.AlertOn then
        return
    end

    local snoozeAge = self:GetAge(self.db.char.LastSnooze)
    if snoozeAge ~= nil and snoozeAge < self.db.profile.config.SnoozeTimeout then
        return
    end

    local TargetAge = self:GetAge(entry.LastTarget)
    if age == nil or age > self.db.profile.config.LastTargetTimeout then
        if self.db.profile.config.PlaySound then
            Sound.Play(Sound.PlayUIExplorerSignalDetection4)  
        end
        self:CPrint(string.format("%s %s: %s", L["AlertHeading"], entry.Name, self:GetStatusStr(entry)))
    end
end

-- Add per-entry config settings to config window
function RareTimer:AddEntriesToConfig()
    for _, entry in pairs(self:GetEntries()) do
        optionsTable.args["Alert" .. entry.Name] = {
            name = entry.Name,
            desc = L["OptAlertDesc"],
            type = "toggle",
            get = function(info)
                return entry.AlertOn
            end,
            set = function(info, value) 
                entry.AlertOn = value
            end,
        }
    end
end

--Suppress alerts for a period
function RareTimer:Snooze()
    local now = GameLib.GetServerTime()
    local duration = math.floor(self.db.profile.config.SnoozeTimeout / 60)
    self.db.char.LastSnooze = now
    self:UpdateSnoozeTimer()
    self:CPrint(string.format(L["SnoozeMsg"], duration))
end

--Init main window
function RareTimer:InitMainWindow()
    local tWndDefinition = {
        Name          = "RareTimerMainWindow",
        --Template      = "CRB_TooltipSimple",
        Sprite        = "BK3:UI_BK3_Holo_InsetFramed_Darker",
        --UseTemplateBG = true,
        Picture       = true,
        Moveable      = true,
        Border        = true,
        Visible       = false,
        AnchorCenter  = {600, 280},
        Escapable     = true,
        
        Pixies = {
            {
                Text          = "RareTimer",
                Font          = "CRB_HeaderHuge",
                TextColor     = "UI_BtnTextBlueNormal",
                AnchorPoints  = "HFILL",
                DT_CENTER     = true,
                DT_VCENTER    = true,
                AnchorOffsets = {0,10,0,30},
            },
        },

        Children = {
            { -- Close button
                Name          = "CloseButton",
                WidgetType    = "PushButton",
                AnchorPoints  = "TOPRIGHT",
                AnchorOffsets = { -21, 1, -1, 21 },
                Base          = "BK3:btnHolo_Clear",
                NoClip        = true,
                Events = { ButtonSignal = function(_, wndHandler, wndControl) wndControl:GetParent():Close() end, },
            },
            { -- Config button
                Name          = "ConfigButton",
                WidgetType    = "PushButton",
                AnchorPoints  = "TOPRIGHT",
                AnchorOffsets = { -45, 1, -25, 21 },
                Base          = "CRB_Basekit:kitBtn_Metal_Options",
                NoClip        = true,
                Events = { ButtonSignal = function(_, wndHandler, wndControl) 
                    local ConfigDialog = Apollo.GetPackage("Gemini:ConfigDialog-1.0").tPackage
                    if ConfigDialog.OpenFrames.RareTimer == nil then
                        ConfigDialog:Open("RareTimer") 
                    else
                        ConfigDialog:Close("RareTimer")
                    end
                end, },
            },
            { -- Grid container
                Name          = "GridContainer", 
                AnchorPoints  = "CENTER",
                AnchorOffsets = { -280, -100, 280, 85 },
                Children = {
                    { -- Grid
                        Name         = "StatusGrid",
                        WidgetType   = "Grid",
                        AnchorFill   = true,
                        Columns      = {
                            { Name = L["Name"], Width = 150 },
                            { Name = L["Status"], Width = 250 },
                            { Name = L["Last kill"], Width = 100 },
                            { Name = L["Health"], Width = 60 },
                        },
                        Events = { WindowLoad = RareTimer.OnWindowLoad, },
                    },
                },
            },
            { -- Ok button
                Name = "OkButton",
                WidgetType = "PushButton",
                Text = Apollo.GetString(kStringOk),
                AnchorPoints = "BOTTOMRIGHT",
                AnchorOffsets = {-120,-45,-20,-15},
                Events = { ButtonSignal = function(_, wndHandler, wndControl) wndControl:GetParent():Close() end, },
            },
            { -- Snooze button
                Name = "SnoozeButton",
                WidgetType = "PushButton",
                Text = L["Snooze"],
                AnchorPoints = "BOTTOMLEFT",
                AnchorOffsets = {20,-45,120,-15},
                Events = { ButtonSignal = function(_, wndHandler, wndControl) RareTimer:Snooze() end, },
            },
            { -- Snooze timer
                Name = "SnoozeTimer",
                WidgetType = "EditBox",
                ReadOnly = true,
                DT_RIGHT = true,
                AnchorPoints = "BOTTOMLEFT",
                AnchorOffsets = {120,-45,175,-15},
                Events = { WindowLoad = RareTimer.UpdateSnoozeTimer, },
            },
        }
    }

    local tWnd = GeminiGUI:Create(tWndDefinition)
    return tWnd:GetInstance()
end

-- Setup main window & window update timer
function RareTimer:OnWindowLoad(wndHandler, wndControl)
    local RT = RareTimer
    self.wndMainControl = wndControl
    RT.windowUpdateTimer = ApolloTimer.Create(10.0, true, "OnWindowUpdateTimer", RT) -- In seconds
    RT:PopulateGrid(wndHandler, wndControl)
end

--Keep the window up to date
function RareTimer:OnWindowUpdateTimer()
    if self.wndMain:IsVisible() then
        local grid = self.wndMain:FindChild("StatusGrid")
        grid:DeleteAll()
        self:PopulateGrid(nil, grid)
        self:UpdateSnoozeTimer()
    end
end

--Update the timer showing the time left in a snooze
function RareTimer:UpdateSnoozeTimer(wndHandler, wndControl)
    local RT = RareTimer
    local snoozeTimer 
    if wndControl == nil then
        snoozeTimer = RT.wndMain:FindChild("SnoozeTimer")
    else
        snoozeTimer = wndControl
    end

    local now = GameLib.GetServerTime()
    local snoozeAge = RT:DiffTime(now, RT.db.char.LastSnooze)
    if snoozeAge == nil or snoozeAge > RT.db.profile.config.SnoozeTimeout then
        RT.db.char.LastSnooze = nil
        snoozeTimer:Show(false)
    else
        snoozeTimer:Show(true)
        local timeleft = math.floor((RT.db.profile.config.SnoozeTimeout - snoozeAge) / 60)
        snoozeTimer:SetText(string.format("%d%s", timeleft, L["m"]))
    end
end

--Populate grid with list of mobs
function RareTimer:PopulateGrid(wndHandler, wndControl)
    local RT = RareTimer
    local tGridData = {}
    local row
    local name, state, killed, health, age
    local entries = RT:GetEntries()
    for i=1, #entries do
        name = entries[i].Name
        state = RT:GetStatusStr(entries[i])
        killed = "--"
        if entries[i].SpawnType == SpawnTypes.Timer then
            age = RT:GetAge(entries[i].LastTick)
        else
            age = RT:GetAge(entries[i].Killed)
        end
        if age ~= nil then
            killed = RT:DurToStr(age)
        end
        health = "--"
        if entries[i].Health ~= nil then
            health = string.format("%d%%", entries[i].Health)
        end
        tGridData[i] = {name, state, killed, health}
    end

    for idx, tRow in ipairs(tGridData) do
        local iCurrRow =  wndControl:AddRow("")
        for cIdx, strCol in ipairs(tRow) do
            wndControl:SetCellText(iCurrRow, cIdx, strCol)
        end
    end
end

-----------------------------------------------------------------------------------------------
-- RareTimerForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function RareTimer:OnOK()
    self.wndMain:Show(false) -- hide the window
end

-- when the Cancel button is clicked
function RareTimer:OnCancel()
    self.wndMain:Show(false) -- hide the window
end

--todo:
--
--Events
--GUI
--History
