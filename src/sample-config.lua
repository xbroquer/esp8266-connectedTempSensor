-- file : config.lua

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!! rename this file into config.lua !!!
-- !!! modify the required parameters   !!!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

local config = {}

config.ENDPOINT = "ESP8266" 

config.WIFI_APS = {
    {["<your_ssid1>"]="<ssid1_pwd>"}
}

config.THINGSPEAK_HOST = "mqtt.thingspeak.com" 
config.THINGSPEAK_CHANNEL = "<channel_id>"
config.THINGSPEAK_KEY_WRITE = "<channel_write_key>"
config.THINGSPEAK_USERID = "<user_id>"
config.THINGSPEAK_PWD =  "<pwd>"
config.THINGSPEAK_PORT = 1883  
--config.ID = node.chipid()

config.LED_BUILTIN = 4
config.PIN_DS18B20 = 3

config.LED_BUILTIN_ON_CONNECTED = true
 
return config 
