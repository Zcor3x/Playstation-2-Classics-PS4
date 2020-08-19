-- God of War II EU

apiRequest(2.2)

local emuObj	= getEmuObject()

-- Graphic improvement: removes corrupted lines on screen with uprender on for PAL version

emuObj.SetGsTitleFix( "forceSimpleFetch", "reserved", { texMode=1 } ) --texMode=1 ?
