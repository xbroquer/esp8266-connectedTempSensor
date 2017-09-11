print("init.lua - Version 0.1 - September 3rd 2017")
print("Author: Xavier BROQUERE")
majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info();
print("NodeMCU "..majorVer.."."..minorVer.."."..devVer)
print("ChipID "..chipid.." FlashID "..flashid)
print("Flash: Size "..flashsize.." Mode "..flashmode.." Speed "..flashspeed)


dofile("completeTempSensor.lua")

