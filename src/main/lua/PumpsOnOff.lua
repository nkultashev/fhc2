--[[
%% properties
197 value
%% weather
%% events
%% globals
HeatingDayMode
--]]

local dayTempToKeep = 20
local nightTempToKeep = dayTempToKeep - 1
local temp = tonumber(fibaro:getValue(197, "value")) -- Текущая температура

SendToPumps = function(cmd)
  fibaro:call(23, cmd); -- Насос: ДОМ
  fibaro:call(25, cmd); -- Насос: БАК
end

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

Debug = function(message)
  fibaro:debug(message)
end

local tempToKeep
local heatingDayMode = (fibaro:getGlobalValue("HeatingDayMode") == "True")

if heatingDayMode then
  Debug('Mode: ' .. Yellow('DAY'))
  tempToKeep = dayTempToKeep
else
  Debug('Mode: ' .. Blue('NIGHT'))
  tempToKeep = nightTempToKeep
end

Debug('Current temp: ' .. temp)
Debug('Temp to maintain: ' .. tempToKeep)

if temp < tempToKeep then
  Debug('Switching pumps ' .. Green('ON'))
  SendToPumps("turnOn");
elseif temp > tempToKeep then
  Debug('Switching pumps ' .. Red('OFF'))
  SendToPumps("turnOff");
end

Debug(Gray('---------------------'))
