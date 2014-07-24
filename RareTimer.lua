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

local defaults = {
    profile = {
	config = {}
    }
}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local version = 0.01
 
local Source = {
    Target = 0,
    Kill = 1,
    Create = 2,
    Destroy = 3
}

local DefaultRares = {
    { 	Name = "Scorchwing",
    	MinEst = "60m",
	MaxEst = "110m",
    },
    { 	Name = "Honeysting Barbtail", 
    	MinEst = "2m",
	MaxEst = "10m",
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
	-- Init

	-- Slash commands
	Apollo.RegisterSlashCommand("raretimer", "OnRareTimerOn", self)

	-- Event handlers
	Apollo.RegisterEventHandler("CombatLogDamage", "OnCombatLogDamage", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)

	-- Status update channel
	self.chanICC = ICCommLib.JoinChannel("RareTimerChannel", "OnDotMessageRareTimerChannelMessage", self)

	-- Timers
	--self.timer = ApolloTimer.Create(5.0, true, "AnnounceTimer", self) -- In seconds
    end
end

-----------------------------------------------------------------------------------------------
-- Saved Information
-----------------------------------------------------------------------------------------------

-- Save
function RareTimer:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end

    local save = {}
    save.Rares = Rares

    return save
end

-- Restore
function RareTimer:OnRestore(eLevel, tData)
    if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
        if tData.Rares  ~= nil then Rares = tData.Rares end
    end
end

-----------------------------------------------------------------------------------------------
-- Slash commands
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/raretimer"
function RareTimer:OnRareTimerOn()
	Print("RareTimer!")
	--self.wndMain:Show(true) -- show the window (Need to init before we can use)
end

-----------------------------------------------------------------------------------------------
-- Event callbacks
-----------------------------------------------------------------------------------------------

-- Capture mobs as they're targeted
function RareTimer:OnTargetUnitChanged(targetID)
    self:UpdateStatus(targetID, Source.Target)
end

-- Capture mobs as they're killed
function RareTimer:OnCombatLogDamage(tEventArgs)
    if tEventArgs.bTargetKilled then
	self:UpdateStatus(tEventArgs.unitTarget, Source.Kill)
    end
end

-- Capture newly loaded/spawned mobs
function RareTimer:OnUnitCreated(unit)
    self:UpdateStatus(unit, Source.Create)
end

-- Capture mobs as they despawn
function RareTimer:OnUnitDestroyed(unit)
    self:UpdateStatus(unit, Source.Destroy)
end

-----------------------------------------------------------------------------------------------
-- RareTimer Functions
-----------------------------------------------------------------------------------------------

-- Update the status of a rare mob
function RareTimer:UpdateStatus(unit, source)
    if self:IsMob(unit) and self:IsNotable(name) then
	--Time table: { nDay, nDayOfWeek, nHour, nMonth, nSecond, nYear, strFormattedTime }
	local time = GameLib.GetServerTime()
	local localTime = GameLib.GetLocalTime()
	local name = unit:GetName()
	local dead = unit:IsDead()
	if dead then
	    if source == Source.Kill then
		strVerb = self:GetString('killed at')
	    else
		strVerb = self:GetString('seen dead at')
	    end
	    local strKilled = string.format("%s %s %s", name, strVerb, localTime.strFormattedTime)
	    Print(strKilled)
	else
	    local health = self:GetHealth(unit)
	    if health ~= nil then
		local strAlive = string.format("%s (%s%%) %s %s", name, health, source .. self:GetString('seen at'), localTime.strFormattedTime)
		Print(strAlive)
	    end
	end
    end
end

-- Get localized string
function RareTimer:GetString(str)
	return str
end

-- Announce data to other clients
function RareTimer:Announce(data)
	for _, val in pairs(data) do
		local t = {}
		t.name = GameLib.GetPlayerUnit():GetName()
		t.message = "Name State Timestamp RareTimerVersion"
		self.chanICC:SendMessage(t)
	end
end

-- Parse announcements from other clients
function RareTimer:OnDotMessageRaretimerChannelMessage(channel, tMsg)
	self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	if self.unitPlayerDisposition == nil or not self.unitPlayerDisposition:IsValid() or RegisteredUsers == nil then
		self.tQueuedUnits = {}
		return
	end	
	if GameLib.GetPlayerUnit():GetName() == tMsg.name then return end
	
	if RegisteredUsers[tMsg.name] ~= nil and type(RegisteredUsers[tMsg.name]) == "table" then
		if RegisteredUsers[tMsg.name].share ~= nil and tMsg.share == nil then return end
		if RegisteredUsers[tMsg.name].nodetype ~= nil and tMsg.nodetype == nil then return end
		
		if RegisteredUsers[tMsg.name].version ~= nil and tMsg.senderversion ~= nil and RegisteredUsers[tMsg.name].version > tMsg.senderversion then return end
		
		if tMsg.timestamp == nil or (RegisteredUsers[tMsg.name].timestamp ~= nil and RegisteredUsers[tMsg.name].timestamp > tMsg.timestamp) then return end
		
		if type(RegisteredUsers[tMsg.name].share) == "table" then
			RegisteredUsers[tMsg.name] = nil
		end
	end
	
	if tMsg.nodetype == nil then
		if type(RegisteredUsers[tMsg.name]) == "table" then 
			return
		end
		if type(tMsg.share) == "table" then return end
		RegisteredUsers[tMsg.name] = tMsg.share
	else
		if tMsg.version ~= nil and tMsg.version > version then
			self.wndMain:FindChild("VersionUpdate"):Show(true)
		end
	    RegisteredUsers[tMsg.name] = tMsg
	end
	--ChatSystemLib.PostOnChannel(2, tMsg.message)
end

-- Trigger periodic announcements
function RareTimer:AnnounceTimer()
	Print("Timer triggered")
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
    if name ~= nil and (name == "Honeysting Barbtail" or name == "Scorchwing") then
	return true
    else
	return false
    end
end

-- Is this a mob?
function RareTimer:IsMob(unit)
    if unit ~= nil and unit:IsValid() and unit:GetType() == 'NonPlayer' then
	return true
    else
	return false
    end
end

-- Spam status of a given mob
function RareTimer:Spam(name, channel)
    --Guild/zone/party
    --Spam health if alive, last death if dead
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

-- Junk !

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
