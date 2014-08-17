-- -*- lua-indent-level: 4; -*-
--- GeminiConfig-1.0 wrapper library.
-- Based on AceConfig 3.0
-- Provides an API to register an options table with the config registry,
-- as well as associate it with a slash command.

--[[
GeminiConfig-1.0

Very light wrapper library that combines all the AceConfig subcomponents into one more easily used whole.

]]

local MAJOR, MINOR = "Gemini:Config-1.0", 1

local tLibError = Apollo.GetPackage("Gemini:LibError-1.0")
local fnErrorHandler = tLibError and tLibError.tPackage and tLibError.tPackage.Error or Print

-- first load the submodules
local function loadModule(dir, mod)
    local func = assert(loadfile(dir .. mod .. "\\" .. mod .. ".lua"))
    if func then
        return xpcall(func, fnErrorHandler)
    end
end

-- This gets the current directory of this file, so it also works when embedded
local strsub, strgsub, debug = string.sub, string.gsub, debug
local dir = string.sub(string.gsub(debug.getinfo(1).source, "^(.+[\\/])[^\\/]+$", "%1"), 2, -1)

loadModule(dir, "GeminiConfigRegistry-1.0")
loadModule(dir, "GeminiConfigCmd-1.0")
loadModule(dir, "GeminiConfigGUI-1.0")
loadModule(dir, "GeminiConfigDialog-1.0")

local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then
    return -- no upgrade is needed
end
local GeminiConfig = APkg and APkg.tPackage or {}
local cfgcmd = Apollo.GetPackage("Gemini:ConfigCmd-1.0").tPackage
local cfgreg = Apollo.GetPackage("Gemini:ConfigRegistry-1.0").tPackage

-- Lua APIs
local pcall, error, type, pairs = pcall, error, type, pairs

-- -------------------------------------------------------------------
-- :RegisterOptionsTable(appName, options, slashcmd, persist)
--
-- - appName - (string) application name
-- - options - table or function ref, see GeminiConfigRegistry
-- - slashcmd - slash command (string) or table with commands, or nil to NOT create a slash command

--- Register a option table with the GeminiConfig registry.
-- You can supply a slash command (or a table of slash commands) to register with GeminiConfigCmd directly.
-- @paramsig appName, options [, slashcmd]
-- @param appName The application name for the config table.
-- @param options The option table (or a function to generate one on demand). http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
-- @param slashcmd A slash command to register for the option table, or a table of slash commands.
-- @usage
-- local GeminiConfig = LibStub("GeminiConfig-3.0")
-- GeminiConfig:RegisterOptionsTable("MyAddon", myOptions, {"/myslash", "/my"})
function GeminiConfig:RegisterOptionsTable(appName, options, slashcmd)
    local ok, msg = pcall(cfgreg.RegisterOptionsTable, self, appName, options)
    if not ok then error(msg, 2) end

    if slashcmd then
        if type(slashcmd) == "table" then
            for _, cmd in pairs(slashcmd) do
                cfgcmd:CreateChatCommand(cmd, appName)
            end
        else
            cfgcmd:CreateChatCommand(slashcmd, appName)
        end
    end
end

Apollo.RegisterPackage(GeminiConfig, MAJOR, MINOR, {})
