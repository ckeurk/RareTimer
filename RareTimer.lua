-----------------------------------------------------------------------------------------------
-- Client Lua Script for RareTimer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "math"
require "string"
require "GameLib"
require "ICCommLib"
 
-----------------------------------------------------------------------------------------------
-- RareTimer Module Definition
-----------------------------------------------------------------------------------------------
local RareTimer = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("RareTimer", false) -- Configure = false
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("RareTimer", true) -- Silent = true
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local Optparse = Apollo.GetPackage("Optparse-0.3").tPackage

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local version = 0.01
 
local Source = {
    Target = 0,
    Kill = 1,
    Create = 2,
    Destroy = 3,
    Combat = 4,
    Report = 5,
    Timer = 6,
}

local States = {
    Unknown = 0, -- Unseen, unreported
    Killed = 1, -- Player saw kill
    Dead = 2, -- Player saw corpse, but not the kill
    Pending = 3, -- Should spawn anytime now
    Alive = 4, -- Up and at full health
    InCombat = 5, -- In combat (not at 100%)
    Expired = 6, -- Been longer than MaxSpawn since last known kill
}

local defaults = {
    profile = {
        config = {
            Slack = 600, --10m, MaxSpawn + Slack = Expired
            CombatTimeout = 300, -- 5m
            Track = {
                L["Scorchwing"],
                L["Honeysting Barbtail"],
                L["Scorchwing Scorchling"],
            }
        },
    },
    realm = {
        LastBroadcast = nil,
        TZOffset = 0, -- Localtime offset from servertime
        mobs = {
            ['**'] = {
                --Name
                State = States.Unknown,
                --Killed
                --Timestamp
                MinSpawn = 0,
                MaxSpawn = 86400, -- 1 day
                --MinDue
                --MaxDue
                --Expires
                --LastReport
            },
            {    
                Name = L["Scorchwing"],
                MinSpawn = 3600, --60m
                MaxSpawn = 6600, --110m
            },
            {    
                Name = L["Honeysting Barbtail"],
                MinSpawn = 120, --2m
                MaxSpawn = 600, --10m
            },
            {    
                Name = L["Scorchwing Scorchling"],
                MinSpawn = 120, --2m
                MaxSpawn = 600, --10m
            },
        }
    }
}
-----------------------------------------------------------------------------------------------
-- RareTimer OnInitialize
-----------------------------------------------------------------------------------------------
function RareTimer:OnInitialize()
    self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, defaults, true)

    -- load our form file
    self.xmlDoc = XmlDoc.CreateFromFile("RareTimer.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
    
    -- Init
    self.IsLoading = false
end

-----------------------------------------------------------------------------------------------
-- RareTimer OnEnable
-----------------------------------------------------------------------------------------------
function RareTimer:OnEnable()
    if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
        -- Slash commands
        Apollo.RegisterSlashCommand("raretimer", "OnRareTimerOn", self)
        self.opt = Optparse:OptionParser{usage="%prog [options]", command="raretimer"}
        SendVarToRover("Self opt", self.opt)
        self:AddOptions()

        -- Event handlers
        Apollo.RegisterEventHandler("CombatLogDamage", "OnCombatLogDamage", self)
        Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
        Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
        Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
        Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
        Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)

        -- Status update channel
        self.channel = ICCommLib.JoinChannel("RareTimerChannel", "OnRareTimerChannelMessage", self)

        -- Timers
        self.timer = ApolloTimer.Create(30.0, true, "OnTimer", self) -- In seconds
        SendVarToRover("Mobs", self.db.realm.mobs)

        -- Config
        self.db.profile.config.TZOffset = self:GetTZOffset()
        
        -- Window
        self.wndMain = Apollo.LoadForm(self.xmlDoc, "RareTimerForm", nil, self)
        self.wndMain:Show(false)
    end
end

-----------------------------------------------------------------------------------------------
-- Slash commands
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/raretimer"
function RareTimer:OnRareTimerOn(sCmd, sInput)
    local s = string.lower(sInput)
    local options, args = self.opt.parse_args(s)
    SendVarToRover("Options", options)
    SendVarToRover("Args", args)
    if options ~= nil then
        if options.list then
            self:CmdList(s)
        elseif options.say then
            self:CmdSpam(s)
        elseif options.debug then
            self:PrintTable(self:GetEntries())
        elseif options.debugconfig then
            self:PrintTable(self.db.profile.config)
        elseif options.update then
            self:OnTimer()
        elseif options.show then
            self.wndMain:Show(true)
        elseif options.hide then
            self.wndMain:Show(false)
        elseif options.toggle then
            self.wndMain:Toggle()
        elseif options.reset then
            self.db:ResetProfile()
        elseif options.test then
            self:SendTestData('Foo!')
            self:SendTestData({msg='Bar', other='baz'})
        end
    end
end

function RareTimer:AddOptions()
    self.opt.add_option{'-l', '--list', action='store_true', dest='list', help='List mobs'}
    self.opt.add_option{'-S', '--say', action='store', dest='say', help='Say mob status'}
    self.opt.add_option{'-c', '--channel', action='store', dest='channel', help='Channel to use for --say', default="p"}
    self.opt.add_option{'-d', '--debug', action='store_true', dest='debug', help='debug mobs'}
    self.opt.add_option{'-D', '--debugconfig', action='store_true', dest='debugconfig', help='debug config'}
    self.opt.add_option{'-u', '--update', action='store_true', dest='update', help='Update states'}
    self.opt.add_option{'-s', '--show', action='store_true', dest='show', help='Show window'}
    self.opt.add_option{'-h', '--hide', action='store_true', dest='hide', help='Hide window'}
    self.opt.add_option{'-t', '--toggle', action='store_true', dest='toggle', help='Toggle window'}
    self.opt.add_option{'-r', '--reset', action='store_true', dest='reset', help='Reset all settings/stored data'}
    self.opt.add_option{'-T', '--test', action='store_true', dest='test', help='Test command'}
end

function RareTimer:ShowHelp(input)
    if input == nil or input == '' then
        self:CPrint("RareTimer commands:")
        self:CPrint("help <command>: Show help")
        self:CPrint("list: List the status of all mobs")
        self:CPrint("spam <channel> <name>: Broadcast the spawn time")
    else
        self:CPrint("Not yet implemented")
    end
end

-----------------------------------------------------------------------------------------------
-- Event handlers
-----------------------------------------------------------------------------------------------

-- Capture mobs as they're targeted
function RareTimer:OnTargetUnitChanged(targetID)
    self:UpdateEntry(targetID, Source.Target)
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
    --Print("Timer triggered")
    self:UpdateState()
    self:BroadcastDB()

    --self.unitPlayerDisposition = GameLib.GetPlayerUnit()
    --if self.unitPlayerDisposition == nil or not self.unitPlayerDisposition:IsValid() or RegisteredUsers == nil then
        --self.tQueuedUnits = {}
        --return
    --end    
end

-- Parse announcements from other clients
function RareTimer:OnRareTimerChannelMessage(channel, tMsg, strSender)
    tMsg.strSender = strSender
    SendVarToRover('Msg', tMsg)
    self:PrintTable(tMsg)
end

-----------------------------------------------------------------------------------------------
-- RareTimer Functions
-----------------------------------------------------------------------------------------------

-- Update the status of a rare mob
function RareTimer:UpdateEntry(unit, source)
    if self:IsMob(unit) and self:IsNotable(unit:GetName()) then
        if unit:IsDead() then
            if source == Source.Kill then
                self:SawKilled(unit)
            else
                self:SawDead(unit)
            end
        else
            self:SawAlive(unit)
        end
    end
end

-- Record a kill
function RareTimer:SawKilled(unit)
    local time = GameLib.GetServerTime()
    local localtime = GameLib.GetLocalTime()
    local entry = self:GetEntry(unit:GetName())
    if entry ~= nil then
        entry.State = States.Killed
        entry.Killed = time
        entry.Timestamp = time
        self:UpdateDue(entry)
        --local strKilled = string.format(L["StateKilled"], localtime.strFormattedTime)
        --Print(string.format("%s %s", unit:GetName(), strKilled))
    end
end

-- Record a corpse
function RareTimer:SawDead(unit)
    local time = GameLib.GetServerTime()
    local entry = self:GetEntry(unit:GetName())
    if entry ~= nil and entry.State ~= States.Killed then
        entry.State = States.Dead
        entry.Killed = time
        entry.Timestamp = time
        self:UpdateDue(entry)
    end
end

-- Record a live mob
function RareTimer:SawAlive(unit)
    local time = GameLib.GetServerTime()
    local entry = self:GetEntry(unit:GetName())
    local health = self:GetHealth(unit)
    local strState
    if health ~= nil and entry ~= nil then
        if health == 100 then
            entry.State = States.Alive
            strState = L["StateAlive"]
        else
            entry.State = States.InCombat
            strState = L["StateInCombat"]
        end
        entry.Timestamp = time
        --local strAlive = string.format(strState, time.strFormattedTime)
        --Print(string.format("%s %s", unit:GetName(), strAlive))
    end
end

-- Announce data to other clients
function RareTimer:Announce(data)
    --todo: sort?
    --for _, val in pairs(data) do
        --local t = {}
        --t.name = GameLib.GetPlayerUnit():GetName()
        --t.message = "Name State Timestamp RareTimerVersion"
        --self.chanICC:SendMessage(t)
    --end
end

-- Calculate % mob health
function RareTimer:GetHealth(unit)
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
        local statusStr = self:GetStatusStr(mob)
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
    if entry.State == States.Unknown then
        strState = L["StateUnknown"]
        when = entry.Timestamp
    elseif entry.State == States.Killed then
        strState = L["StateKilled"]
        when = entry.Killed
    elseif entry.State == States.Dead then
        strState = L["StateDead"]
        when = entry.Killed
    elseif entry.State == States.Pending then
        strState = L["StatePending"]
        when = entry.Due
    elseif entry.State == States.Alive then
        strState = L["StateAlive"]
        when = entry.Timestamp
    elseif entry.State == States.InCombat then
        strState = L["StateInCombat"]
        when = entry.Timestamp
    elseif entry.State == States.Expired then
        strState = L["StateExpired"]
        when = entry.Timestamp
    end
    if when == nil then
        when = GameLib.GetServerTime()
        when.nYear = 1970
    end
    local strWhen = self:FormatDate(self:LocalTime(when))
    local strStatus = string.format(strState, strWhen)
    return string.format("%s: %s", entry.Name, strStatus)
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
        msg = ''
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

-- Progress state (expire entries, etc.)
function RareTimer:UpdateState()
    for _, mob in pairs(self:GetEntries()) do
        -- Expire entries
        if mob.State ~= States.Unknown and mob.State ~= States.Expired and self:IsExpired(mob) then
            self:SetState(mob, States.Expired)
            return
        elseif mob.State == States.InCombat and self:IsCombatExpired(mob) then
            self:SetState(mob, States.Expired)
            return
        -- Set pending spawn
        elseif self:IsDue(mob) then
            self:SetState(mob, States.Pending)
            return
        end
    end
end

-- Check if an entry is due to spawn
function RareTimer:IsDue(entry)
    local killedAgo = self:GetAge(entry.Killed)
    if killedAgo == nil then
        return
    end

    -- Move the due time up if we only saw the corpse, not the kill
    local due = entry.MinSpawn
    if State == States.Dead then
        due = due - self.db.profile.config.Slack
    end

    if (entry.State == States.Killed or entry.State == States.Dead) and killedAgo > due then
        return true
    else
        return false
    end
end

-- Check if an entry is expired
function RareTimer:IsExpired(entry)
    local ago = self:GetAge(entry.Timestamp)
    local killedAgo = self:GetAge(entry.Killed)
    local maxAge = entry.MaxSpawn + self.db.profile.config.Slack
    if (ago ~= nil and ago > maxAge) or (killedAgo ~= nil and killedAgo > maxAge) then
        return true
    else
        return false
    end
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
function RareTimer:SetState(entry, state)
    local now = GameLib.GetServerTime()
    entry.State = state
    entry.Timestamp = now
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

-- Convert a duration in seconds to a shortform string
function RareTimer:DurToStr(dur)
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

-- Send contents of DB to other clients (if needed)
function RareTimer:BroadcastDB()
    --todo
end

-- Send data to other clients
function RareTimer:SendData(msg)
    if type(msg) ~= 'table' then
        msg = {strMsg = msg}
    end
    self.channel:SendMessage(msg)
end

function RareTimer:SendTestData(msg)
    if type(msg) ~= 'table' then
        msg = {strMsg = msg}
    end
    self:OnRareTimerChannelMessage(self.channel, msg, "TestMsg")
end

-- Convert server time to local time
function RareTimer:LocalTime(date)
    local serverTime = self:ToLuaTime(date)
    local localTime = serverTime + self.db.realm.TZOffset
    return self:ToWsTime(localTime)
end

-- Calculate the offset between server time and local time
function RareTimer:GetTZOffset()
    return self:DiffTime(GameLib.GetLocalTime(), GameLib.GetServerTime())
end

-- Get the list of mob entries
function RareTimer:GetEntries()
    return self.db.realm.mobs
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

-----------------------------------------------------------------------------------------------
-- Junk !
-----------------------------------------------------------------------------------------------

  --local disposition = unit:GetDispositionTo(GameLib.GetPlayerUnit())

--  if unit:IsValid() and not unit:IsDead() and not unit:IsACharacter() and 
--     (table.find(unitName, self.rareNames) or table.find(unitName, self.customNames)) then
--    local item = self.rareMobs[unit:GetName()]
--    if not item then
--      if self.broadcastToParty and GroupLib.InGroup() then
--        -- no quick way to party chat, need to find the channel first
--        for _,channel in pairs(ChatSystemLib.GetChannels()) do
--          if channel:GetType() == ChatSystemLib.ChatChannel_Party then
--            channel:Send("Rare detected: " .. unit:GetName())
--          end
--        end
--      end
--    end
--  end
--
    --Yellowtail Fury: id 5380606, Elite 0, ClassId 23, Archetype[idArchetype] = 20 (Tank)
    --Perfect Stag: id: 4403258, Elite 0, ClassId 23, Archetype = 10 (MeleeDPS)
    --Sproutlings: nil name, nil archetype
    --Galactium Node: Archetype 29
    --Scorchwing: Elite 2, archetype 17 (Vehicle)

    --Rares table:
    --Name
    --Dead
    --Timestamp
    --Expires

    --Time table: { nDay, nDayOfWeek, nHour, nMonth, nSecond, nYear, strFormattedTime }

            --local strKilled = string.format("%s %s %s", name, strVerb, localTime.strFormattedTime)
            --
            --Trigger events: Rare mob alive, rare mob dead
    --todo: Barbtail goes unknown too quickly after alive
    --todo: Use DurToStr to add next spawn to list
