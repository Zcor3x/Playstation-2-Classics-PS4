require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])
apiRequest(0.4)

-- The Legend of Spyro: A New Beginning

local eeObj		= getEEObject()
local emuObj	= getEmuObject()

eeInsnReplace(0x1849b8, 0x44840800, 0x00000000)	-- Fixes HUD and menu display.


-- Graphic improvement: removes corrupted lines on screen with uprender enabled, for PAL version

emuObj.SetGsTitleFix( "forceSimpleFetch", "reserved", { texMode=1 } ) --texMode=1 ?
emuObj.SetGsTitleFix( "forceSimpleFetch", "reserved", { texMode=2 } ) --texMode=2 is BILINEAR