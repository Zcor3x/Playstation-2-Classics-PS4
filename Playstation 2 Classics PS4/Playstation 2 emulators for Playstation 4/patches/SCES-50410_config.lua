-- Ace Combat: Distant Thunder

-- DATE: 09/06/2019

apiRequest(2.2)

local emuObj 		= getEmuObject()

-- Fix clouds shader
emuObj.SetGsTitleFix( "forceSimpleFetch", "reserved", { texMode=2  } )
