apiRequest(2.2)

-- Wrong sky shader

local emuObj 	= getEmuObject()

-- Fix for wrong sky shader

emuObj.SetGsTitleFix( "forceSimpleFetch", "reserved", { texMode=1 } )
emuObj.SetGsTitleFix( "forceSimpleFetch", "reserved", { texMode=2 } )

-- Collision detection fix.

eeInsnReplace(0x131EB8, 0x4B00682C, 0x48498800)
eeInsnReplace(0x131EC8, 0x4B0C682C, 0x4B00682C)
eeInsnReplace(0x131FB8, 0x48498800, 0x484A8800)
eeInsnReplace(0x131EC4, 0x484A8800, 0x4B0C682C)
