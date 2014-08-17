GeminiConfig
============

This is a port of AceConfig-3.0 and AceGUI-3.0 to Wildstar. It's
currently in partial working status. The most useful part,
GeminiConfigDialog is mostly working but some items are still missing.

The notification code in Config Registry is also not working.

This addon requires the following libraries to be loaded:

* Lib:GeminiGUI-1.0
* GeminiColor (for color picker only)
* Optionally LibError-1.0 for error reporting.


Simple usage
=============

Registering a config table:
```Lua
  local GeminiConfig = Apollo.GetPackage("Gemini:Config-1.0").tPackage
  GeminiConfig:RegisterOptionsTable(strAddonNAme, tConfigOptions[, strSlashName | tSlashNames])
```
Opening a config dialog:
```Lua
  Apollo.GetPackage("Gemini:ConfigDialog-1.0").tPackage:Open(strAddonName)
```
For details on the option table format, please refer to the AceConfig documentation:

http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
