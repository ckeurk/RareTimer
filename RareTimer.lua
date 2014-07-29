-----------------------------------------------------------------------------------------------
-- Client Lua Script for RareTimer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "math"
require "string"
 
-----------------------------------------------------------------------------------------------
-- RareTimer Module Definition
-----------------------------------------------------------------------------------------------
local RareTimer = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("RareTimer", false) -- Configure = false
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("RareTimer", true) -- Silent = true
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage


 
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
            LastBroadcast = nil,
            Slack = 600, --10m, MaxSpawn + Slack = Expired
            CombatTimeout = 300, -- 5m
        },
        mobs = {
            ['**'] = {
                --Name
                State = States.Unknown,
                --Killed
                --Timestamp
                --MinSpawn
                --MaxSpawn
                --Due
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
end

-----------------------------------------------------------------------------------------------
-- RareTimer OnEnable
-----------------------------------------------------------------------------------------------
function RareTimer:OnEnable()
    if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
        -- Slash commands
        Apollo.RegisterSlashCommand("raretimer", "OnRareTimerOn", self)

        -- Event handlers
        Apollo.RegisterEventHandler("CombatLogDamage", "OnCombatLogDamage", self)
        Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
        Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
        Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)

        -- Status update channel
        self.chanICC = ICCommLib.JoinChannel("RareTimerChannel", "OnRareTimerChannelMessage", self)

        -- Timers
        self.timer = ApolloTimer.Create(30.0, true, "OnTimer", self) -- In seconds
        SendVarToRover("Mobs", self.db.profile.mobs)
    end
end

-----------------------------------------------------------------------------------------------
-- Slash commands
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/raretimer"
function RareTimer:OnRareTimerOn(sCmd, sInput)
    local s = string.lower(sInput)
    if s ~= nil and s ~= '' and s ~= 'help' then
        if s == "list" then
            self:CmdList(s)
        elseif s:find("spam ") == 1 then
            self:CmdSpam(s)
        elseif s == "debug" then
            self:PrintTable(self.db.profile.mobs)
        elseif s == "update" then
            self:OnTimer()
        end
    else
        self:ShowHelp(s)
    end
    --Print(inspect(self.db))
    --for a,b in pairs(L) do
        --Print("A: " .. a .. " B: " .. b)
    --end
    --Print("RareTimer!")
    --self.wndMain:Show(true) -- show the window (Need to init before we can use)
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

-- Capture newly loaded/spawned mobs
function RareTimer:OnUnitCreated(unit)
    self:UpdateEntry(unit, Source.Create)
end

-- Capture mobs as they despawn
function RareTimer:OnUnitDestroyed(unit)
    self:UpdateEntry(unit, Source.Destroy)
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
    local entry = self:GetEntry(unit:GetName()) or {}
    entry.State = States.Killed
    entry.Killed = time
    entry.Timestamp = time
    --entry.Expires = time + entry.MaxSpawn + self.db.config.Slack
    --entry.Due = time + entry.MinSpawn
    local strKilled = string.format(L["StateKilled"], localtime.strFormattedTime)
    --Print(string.format("%s %s", unit:GetName(), strKilled))
end

-- Record a corpse
function RareTimer:SawDead(unit)
    local time = GameLib.GetServerTime()
    local entry = self:GetEntry(unit:GetName()) or {}
    if entry.State ~= States.Killed then
        entry.State = States.Dead
        entry.Killed = time
        entry.Timestamp = time
        --entry.Expires = time + entry.MaxSpawn + self.db.config.Slack
        --entry.Due = time + entry.MinSpawn
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
        local strAlive = string.format(strState, time.strFormattedTime)
        --Print(string.format("%s %s", unit:GetName(), strAlive))
    end
end

-- Announce data to other clients
function RareTimer:Announce(data)
    --todo: sort?
    for _, val in pairs(data) do
        local t = {}
        t.name = GameLib.GetPlayerUnit():GetName()
        t.message = "Name State Timestamp RareTimerVersion"
        self.chanICC:SendMessage(t)
    end
end

-- Parse announcements from other clients
function RareTimer:OnRareTimerChannelMessage(channel, tMsg)
    self:CPrint("Msg Received on " .. channel)
    self.PrintTable(tMsg)
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
    for _, entry in pairs(self.db.profile.mobs) do
        if entry.Name == name then
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
    for _, mob in pairs(self.db.profile.mobs) do
        self:CPrint(self:GetStatusStr(mob))
    end
end

-- Generate a status string for a given entry
function RareTimer:GetStatusStr(entry)
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
    local strWhen = self:FormatDate(when)
    return string.format("%s: %s", entry.Name, string.format(strState, strWhen))
end

-- Convert a date to a string in the format YYYY-MM-DD hh:mm:ss pp
function RareTimer:FormatDate(date)
    return string.format('%d-%02d-%02d %s', date.nYear, date.nMonth, date.nDay, date.strFormattedTime)
end

-- Get the db entry for a mob
function RareTimer:GetEntry(name)
    for _, mob in pairs(self.db.profile.mobs) do
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
    local ago
    local killedAgo
    local maxAge
    local now = GameLib.GetServerTime()
    -- Now is nil while loading
    if now == nil then
        return
    end
    for _, mob in pairs(self.db.profile.mobs) do
        if mob.Timestamp ~= nil then
            ago = self:DiffTime(now, mob.Timestamp)
        else
            ago = nil
        end
        if mob.Killed ~= nil then
            killedAgo = self:DiffTime(now, mob.Killed)
        else
            killedAgo = nil
        end
        maxAge = mob.MaxSpawn + self.db.profile.config.Slack
        -- Expire entries
        if mob.State ~= States.Unknown and mob.State ~= States.Expired
            and ((ago ~= nil and ago > maxAge) or (killedAgo ~= nil and killedAgo > maxAge)) then
            mob.State = States.Expired
            mob.Timestamp = now
            return
        elseif mob.State == States.InCombat and (ago == nil or ago > self.db.profile.config.CombatTimeout) then
            mob.State = States.Expired
            mob.Timestamp = now
            return
        -- Set pending spawn
        elseif killedAgo ~= nil and ((mob.State == States.Killed and killedAgo > mob.MinSpawn)
            or (mob.State == States.Dead and killedAgo > mob.MinSpawn - self.db.profile.config.Slack)) then
            mob.State = States.Pending
            mob.Timestamp = now
            return
        end
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
        nYear = luaTime.year,
        nMonth = luaTime.month,
        nDay = luaTime.day,
        nHour = luaTime.hour,
        nMinute = luaTime.min,
        nSecond = luaTime.sec
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
