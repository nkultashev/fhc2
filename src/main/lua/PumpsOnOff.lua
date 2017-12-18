--[[
%% properties
197 value
%% weather
%% events
%% globals
HeatingDayMode
--]]
-- Above is a control header for a Fibaro HC2 engine.
-- % properties - trigger the scene when a device property changed.
-- % globals - trigger the scene when a global variable value changed.

local thermDeviceId = 197                 -- Id of the thermometer device
local dayTempToKeep = 20                  -- Temp. to maintain when DAY mode 
local nightTempToKeep = dayTempToKeep - 1 -- Temp. to maintain when NIGHT mode 

--
-- SendCommand: Send a command to controlled devices
--
SendCommand = function(cmd)
  fibaro:call(23, cmd); -- Pump: HOME
  fibaro:call(25, cmd); -- Pump: HEAT. ACC.
end

--
-- Functions to write color text on the debug console
--
Color = function(color, message)
  return string.format('<span style="color:%s;">%s</span>', color, message)
end

Green = function(message)
  return Color('green', message)
end

Red = function(message)
  return Color('red', message)
end

Gray = function(message)
  return Color('gray', message)
end

Blue = function(message)
  return Color('blue', message)
end

Yellow = function(message)
  return Color('yellow', message)
end

--
-- Debug: a shortcut to fibaro:debug(...) function
--
Debug = function(message)
  fibaro:debug(message)
end

--
-- MAIN PROCEDURE
--
-- Get current temp. from the declared thermometer...
local temp = tonumber(fibaro:getValue(thermDeviceId, "value")) 

-- Get current mode from the global variable HeatingDayMode...
local heatingDayMode = (fibaro:getGlobalValue("HeatingDayMode") == "True")

-- Save required temp. to the tempToKeep variable and report the current mode...
local tempToKeep
if heatingDayMode then
  Debug('Mode: ' .. Yellow('DAY'))
  tempToKeep = dayTempToKeep
else
  Debug('Mode: ' .. Blue('NIGHT'))
  tempToKeep = nightTempToKeep
end

-- Report some info...
Debug('Current temp: ' .. temp)
Debug('Temp to maintain: ' .. tempToKeep)

-- Send on/off command to the controlled devices depending on the current temp...
if temp < tempToKeep then
  Debug('Switching pumps ' .. Green('ON'))
  SendCommand("turnOn");
elseif temp > tempToKeep then
  Debug('Switching pumps ' .. Red('OFF'))
  SendCommand("turnOff");
end

Debug(Gray('---------------------'))
