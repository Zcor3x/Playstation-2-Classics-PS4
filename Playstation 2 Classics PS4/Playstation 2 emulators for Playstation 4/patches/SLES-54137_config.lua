apiRequest(1.2)

local gpr    	= require("ee-gpr-alias")
local emuObj	= getEmuObject()
local eeObj		= getEEObject()

-- Graphic improvement: removes corrupted lines on screen with uprender enabled on PAL version

emuObj.SetGsTitleFix( "forceSimpleFetch", "reserved", { texMode=1 } )
emuObj.SetGsTitleFix( "forceSimpleFetch", "reserved", { texMode=2 } ) --texMode=2 is BILINEAR
