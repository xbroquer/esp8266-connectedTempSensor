
-- load configuration file
PARAMS = require("config")

local value = gpio.LOW
local timerBlink = 0
local timerReadAndSendTemp = 1

-- Initialise the pin of BuiltIn Led
gpio.mode(PARAMS.LED_BUILTIN, gpio.OUTPUT)
gpio.write(PARAMS.LED_BUILTIN, gpio.HIGH)

-- Initialise the pin of one wire bus (ds18b20 sensor)
ds18b20.setup(PARAMS.PIN_DS18B20)

-- Function toggles LED state
function toggleLED ()
    if value == gpio.LOW then
        value = gpio.HIGH
    else
        value = gpio.LOW
    end
    gpio.write(PARAMS.LED_BUILTIN, value)
end

function sendTempToThingSpeak(tempIn)
    m = mqtt.Client(PARAMS.ENDPOINT, 120, PARAMS.THINGSPEAK_USERID, PARAMS.THINGSPEAK_PWD)
    m:on("connect", function(client) print ("mqtt: connected") end)
    m:on("offline", function(client) print ("mqtt: offline") end)
    m:on("message", function(client, topic, data) 
      print(topic .. ":" ) 
      if data ~= nil then
        print(data)
      end
    end)
    
    m:connect(PARAMS.THINGSPEAK_HOST, PARAMS.THINGSPEAK_PORT, 0, function(client)
      print("connected to MQTT Broker")
      local t = tempIn
      client:publish(
          "channels/"..PARAMS.THINGSPEAK_CHANNEL.."/publish/"..PARAMS.THINGSPEAK_KEY_WRITE, 
          "field1="..t, 
          0, 
          0, 
          function(client) print("Temperature sent") end)
    end,
    function(client, reason)
      print("failed reason: " .. reason)
    end)
    status = m:close()
end

function readTemp()
    -- read all sensors and print all measurement results
    temperature = -1
    ds18b20.read(
        function(ind,rom,res,temp,tdec,par)
            --print(ind,string.format("%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X",string.match(rom,"(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")),res,temp,tdec,par)
            temperature = temp
             print("temperature is "..temperature)
        end,{});
   return   temperature   
end

function readAndSendTemp()
    sendTempToThingSpeak(readTemp())
end


_WIFI_CURRENT_AP = 1
_WIFI_FAIL_COUNTER = 0
wifi.setmode(wifi.STATION)
NET_AP,NET_PASSWORD =  next(PARAMS.WIFI_APS[_WIFI_CURRENT_AP])

station_cfg={}
station_cfg.ssid=NET_AP
station_cfg.pwd=NET_PASSWORD
wifi.sta.config(station_cfg)

if wifi.sta.getip() == nil then
    local _boot_wifi_counter = 0
    local _boot_wifi_timer = tmr.create()
    _boot_wifi_timer:alarm(2000, tmr.ALARM_AUTO, function()
        if _boot_wifi_counter == 0 then
            NET_AP,NET_PASSWORD =  next(PARAMS.WIFI_APS[_WIFI_CURRENT_AP])
            station_cfg.ssid=NET_AP
            station_cfg.pwd=NET_PASSWORD
            wifi.sta.config(station_cfg)
            print("Connecting to: "..NET_AP)
        end
        if wifi.sta.getip() == nil then     
            print(" Wait for IP --> "..wifi.sta.status()) 
            _boot_wifi_counter = _boot_wifi_counter + 1
            if _boot_wifi_counter == 6 then
                _boot_wifi_counter = 0
                _WIFI_CURRENT_AP = _WIFI_CURRENT_AP + 1
                if _WIFI_CURRENT_AP > #PARAMS.WIFI_APS then
                    _WIFI_CURRENT_AP = 1
                end
             end   
        else            
            _boot_wifi_timer:stop()
            print("connected to "..station_cfg.ssid)
        end
 
    end)
end

_wifi_keepalive_timer = tmr.create()
_wifi_keepalive_timer:register(5000, tmr.ALARM_AUTO, function()
    if wifi.sta.status() ~= 5 then
        _WIFI_FAIL_COUNTER = _WIFI_FAIL_COUNTER + 1
        print ("WiFi fail: "..wifi.sta.status())
    else
        WIFI_FAIL_COUNTER = 0
    end
    if WIFI_FAIL_COUNTER > 10 then        
        print "Node reboot..."
        node.restart()
    end       
end)

tmr.alarm(timerBlink, 200, 1, toggleLED)

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
 print("\n\tWIFI STATION - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
 T.BSSID.."\n\tChannel: "..T.channel)
 tmr.alarm(timerBlink, 1000, 1, toggleLED)
 tmr.stop(timerReadAndSendTemp)
end)

wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
 print("\n\tWIFI STATION - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
 T.BSSID.."\n\treason: "..T.reason)
 tmr.alarm(timerBlink, 200, 1, toggleLED)
 tmr.stop(timerReadAndSendTemp)
end)

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
  print("\n\tWIFI STATION - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
  T.netmask.."\n\tGateway IP: "..T.gateway)
  tmr.stop(timerBlink)
  if PARAMS.LED_BUILTIN_ON_CONNECTED == true then  
    gpio.write(PARAMS.LED_BUILTIN, gpio.LOW)
  else
    gpio.write(PARAMS.LED_BUILTIN, gpio.HIGH)
  end
  tmr.alarm(timerReadAndSendTemp, 1000*60*30, 1, readAndSendTemp)
end)



