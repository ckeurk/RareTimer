--[[

LUA MODULE

Based on http://lua-users.org/wiki/ModulePythonicOptparse, ported to Wildstar by Kowh.

  pythonic.optparse - Lua-based partial reimplementation of Python's
      optparse [2-3] command-line parsing module.

SYNOPSIS

  local Optparse = Apollo.GetPackage("Optparse-0.3").tPackage
  local opt = OptParse:OptionParser{usage="%prog [options] [...]",
                           version="foo 1.23", add_help_option=false}
  opt.add_option{"-h", "--help", action="store_true", dest="help",
                 help="give this help", default="default"}
  opt.add_option{
    "-f", "--force", dest="force", action="store_true",
    help="force overwrite of output file"}

  local options, args = opt.parse_args()

DESCRIPTION

  This library provides a command-line parsing[1] similar to Python optparse [2-3].

  Note: Python also supports getopt [4].

STATUS
  
  This module is fairly basic but could be expanded.
  
API

  See source code and also compare to Python's docs [2,3] for details because
  the following documentation is incomplete.
  
  opt = OptionParser {command=command, usage=usage, version=version, 
    add_help_option=add_help_option, callback_write=callback_write}
  
    Create command line parser.

    callback_write: If provided, this function will be used for output instead of the command channel
    command: Name of the slash command
  
  opt.add_options{shortflag, longflag, action=action, metavar=metavar, dest=dest, help=help, default=default}
  
    Add command line option specification.  This may be called multiple times.
 
  opt.parse_args() --> options, args
  
    Perform argument parsing.
 
DEPENDENCIES

  None (other than Lua 5.1 or 5.2)
  
REFERENCES

  [1] http://lua-users.org/wiki/CommandLineParsing
  [2] http://docs.python.org/lib/optparse-defining-options.html
  [3] http://blog.doughellmann.com/2007/08/pymotw-optparse.html
  [4] http://docs.python.org/lib/module-getopt.html

LICENSE

  (c) 2008-2011 David Manura.  Licensed under the same terms as Lua (MIT).

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  (end license)

 --]]

local MAJOR, MINOR = "Optparse-0.3", 20111128
local Lib = {}
 
local ipairs = ipairs
local unpack = unpack
local table = table

function Lib:OptionParser(t)
  local usage = t.usage
  local callback_write = t.callback_write
  local command = t.command or "<command>"

  local o = {}
  local option_descriptions = {}
  local option_of = {}

  function o.tokenize(str)
    if str == nil or #str == 0 then
      return {}
    end

    local i, i1, i2 = 1, 1, 1
    local t = {}

    local function token()
      tok = string.sub(str, i, i2)
      table.insert(t, tok)
    end

    local function find(pattern)
      i1, i2 = string.find(str, pattern, i)
      return i1 ~= nil
    end

    local function findspaces() return find("^%s+") end
    local function findquote() return find("^(%-*[^%s]+'.-')") end
    local function findquotes() return find("^(%-*[^%s]+\".-\")") end
    local function findwords() return find("^(\-*[^%s]+)") end
    local function findend() return find("^$") end

    while true do
      if findspaces() then
        i = i2 + 1
      elseif findquote() or findquotes() or findwords() then
        token()
        i = i2 + 1
      elseif findend() then
        break
      else
        --Invalid input
        return
      end
    end
    return t
  end
  
  function o.write(s)
      if callback_write ~= nil then
          callback_write(self, s)
      else
          ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, s, "")
      end
  end

  function o.error(s)
      ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Debug, "Error: " .. s, "")
  end

  function o.add_option(optdesc)
    option_descriptions[#option_descriptions+1] = optdesc
    if optdesc.default then
        if optdesc.help == nil then 
          optdesc.help = '' 
        end
        optdesc.help = optdesc.help .. string.format(" [default: %s]", tostring(optdesc.default))
    end

    for _,v in ipairs(optdesc) do
      option_of[v] = optdesc
    end
  end

  function o.parse_args(strArgs)
    if strArgs == nil then
        return
    end

    -- expand options (e.g. "--input=file" -> "--input", "file")
    local arg = o.tokenize(strArgs)

    for i=#arg,1,-1 do local v = arg[i]
      local flag, val = string.match(v, '^(%-%-%w+)=(.*)')
      if flag then
        arg[i] = flag
        table.insert(arg, i+1, val)
      end
    end

    local options = {}
    local args = {}
    local i = 1
    while i <= #arg do local v = arg[i]
      local optdesc = option_of[v]
      if optdesc then
        local action = optdesc.action
        local val
        if action == 'store' or action == nil then
          i = i + 1
          val = arg[i]
          if not val then
            if optdesc.default then 
              val = optdesc.default
            else
              o.write('option requires an argument ' .. v) 
              return
            end
          end
        elseif action == 'store_true' then
          val = true
        elseif action == 'store_false' then
          val = false
        end
        options[optdesc.dest] = val
      else
        if string.match(v, '^%-') then 
          o.write('invalid option ' .. v) 
          return
        end
        args[#args+1] = v
      end
      i = i + 1
    end

    if options.help then
      o.print_help()
    elseif options.version then
      o.write(t.version .. "\n")
    else
      return options, args
    end
  end

  local function flags_str(optdesc)
    local sflags = {}
    local action = optdesc.action
    for _,flag in ipairs(optdesc) do
      local sflagend
      if action == nil or action == 'store' then
        local metavar = optdesc.metavar or optdesc.dest:upper()
        sflagend = #flag == 2 and ' ' .. metavar
                              or  '=' .. metavar
      else
        sflagend = ''
      end
      sflags[#sflags+1] = flag .. sflagend
    end
    return table.concat(sflags, ', ')
  end

  function o.print_help()
    o.write("Usage: " .. usage:gsub('%%prog', command) .. "\n")
    o.write("\n")
    o.write("Options:\n")
    local maxwidth = 0
    for _,optdesc in ipairs(option_descriptions) do
      maxwidth = math.max(maxwidth, #flags_str(optdesc))
    end
    for _,optdesc in ipairs(option_descriptions) do
      o.write("  " .. ('%-'..maxwidth..'s  '):format(flags_str(optdesc))
                      .. optdesc.help .. "\n")
    end
  end

  if t.add_help_option == nil or t.add_help_option == true then
    o.add_option{"--help", action="store_true", dest="help",
                 help="show this help message and exit"}
  end

  if t.version then
    o.add_option{"--version", action="store_true", dest="version",
                 help="output version info."}
  end

  return o
end

function Lib:OnLoad()
end

function Lib:OnDependencyError(strDep, strError)
  return false
end

Apollo.RegisterPackage(Lib, MAJOR, MINOR, {})
