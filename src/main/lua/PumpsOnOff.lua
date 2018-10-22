--[[
%% properties
197 value
%% weather
%% events
%% globals
HeatingDayMode
HeatingDayAt
HeatingNightAt
HeatingDayTemp
HeatingNightTemp
--]]

local dayTempToKeep   = tonumber(fibaro:getGlobalValue("HeatingDayTemp"))
local nightTempToKeep = tonumber(fibaro:getGlobalValue("HeatingNightTemp"))
local temp     = tonumber(fibaro:getValue(197, "value")) -- Текущая температура в доме
local hum      = tonumber(fibaro:getValue(198, "value")) -- Текущая влажность в доме
local outTemp  = tonumber(fibaro:getValue(224, "value")) -- Температура на улице
local outLight = tonumber(fibaro:getValue(225, "value")) -- Освещение на улице
local dbHost   = "10.1.0.3:81" -- Адрес сервера БД

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

--
-- SendStat: Отправка статистики на сервер БД
--
SendStat = function(temperature, humidity, tempToMaintain, mode, command, outsideTemp, outsideLight)
  local http = net.HTTPClient()
  local payload = "/fibaro-stats/pumps_post.php" ..
    "?temperature="    .. temperature ..
    "&humidity="       .. humidity ..
    "&tempToMaintain=" .. tempToMaintain ..
    "&mode="           .. mode ..
    "&command="        .. command ..
  	"&outsideTemp="    .. outsideTemp ..
  	"&outsideLight="    .. outsideLight
  local url = "http://" .. dbHost .. payload
  
  Debug("Sending data...")
  Debug(Gray(url))
  
  local httpClient = net.HTTPClient({timeout=5000})
  httpClient:request(url, {
      options = {
          method = "GET"
      },
      success = function(resp)
          local status = tonumber(resp.status)
          if status == 200 then
            Debug("Status: " .. Green(status))
          else
            Debug("Status: " .. Red(status))
            Debug(Gray("--- Server response ---"))
            Debug(Gray(resp.data))
          end
      end,
      error = function(error)
          Debug("error: " .. Red(error))
      end
    }
  )
end

IsDayMode = function()
  local currentHour = os.date('*t').hour -- Текущий час
  currentHour = currentHour + tonumber(fibaro:getGlobalValue("HeatingTZShift")) -- Ручная коррекция времени 
  
  -- Сейчас день?
  local isDay = 
    (currentHour >= tonumber(fibaro:getGlobalValue("HeatingDayAt"))) and 
    (currentHour <  tonumber(fibaro:getGlobalValue("HeatingNightAt")))
  
  -- Прочитаем сохранённые режимы...
  local isDayAutoMode   = fibaro:getGlobalValue("HeatingDayAuto") == 'True' -- Это устанавливает программа
  local isDayManualMode = fibaro:getGlobalValue("HeatingDayMode") == 'True' -- Это меняет человек

  local strAutoMode = isDay and Yellow('DAY') or Blue('NIGHT')
  
  -- Начался новый период?
  -- Запомним новый режим и сбросим ручной режим в текущее значение...
  if (isDayAutoMode ~= isDay) then
    Debug('Now is ' .. Yellow(currentHour) .. ' hours')
    Debug('Switching mode to: ' .. strAutoMode)
    
    fibaro:setGlobal("HeatingDayAuto", isDay and 'True' or 'False')
    fibaro:setGlobal("HeatingDayMode", isDay and 'True' or 'False')
    
    isDayManualMode = isDay
  end
  
  local strManualMode = isDayManualMode and Yellow('DAY') or Blue('NIGHT')
  Debug('Now is ' .. strAutoMode .. ', manual mode is ' .. strManualMode .. ' => mode is ' .. strManualMode)
  
  return isDayManualMode
end
    
--
-- Определим, какую температуру нужно поддерживать...
--
local tempToKeep
local heatingDayMode = IsDayMode()
local mode;

if heatingDayMode then
  Debug('Mode: ' .. Yellow('DAY'))
  mode = 'DAY'
  tempToKeep = dayTempToKeep
else
  Debug('Mode: ' .. Blue('NIGHT'))
  mode = 'NIGHT'
  tempToKeep = nightTempToKeep
end

Debug('Current temp: ' .. temp)
Debug('Temp to maintain: ' .. tempToKeep)

---
-- Включаем или выключаем насосы...
---
local cmd = ""
if temp < tempToKeep then
  Debug('Switching pumps ' .. Green('ON'))
  cmd = "turnOn"
elseif temp >= tempToKeep then
  Debug('Switching pumps ' .. Red('OFF'))
  cmd = "turnOff"
end

if cmd ~= "" then
  SendToPumps(cmd)
end

SendStat(temp, hum, tempToKeep, mode, cmd, outTemp, outLight)

Debug(Gray('---------------------'))
