
apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

-- Bully bug 9392
-- Performace fix
local emuObj = getEmuObject()	
local thresholdArea = 600
emuObj.SetGsTitleFix( "ignoreUpRender", thresholdArea , {alpha=0x80000044 , zmsk=1 , tw=4, th=4  } )


