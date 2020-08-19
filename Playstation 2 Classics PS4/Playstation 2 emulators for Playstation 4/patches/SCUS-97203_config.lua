require("ee-gpr-alias")
apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local emuObj		= getEmuObject()	
-- fix vision logo (Wild Arms 3)
local thresholdArea = 0 -- ignore alls items : fix #112276
emuObj.SetGsTitleFix( "ignoreUpRender", thresholdArea , {  texType = 3, cbp = 0x2390, tbp = 0x288000} )


-- fix bug #9072
-- this is caused by a wrong string, which we patch directly on the disc.
emuMediaPatch(0x438a, 12 + 0x174, { 0x6e5c2535 }, { 0x11202535 })

-- Bug#8907. accuracy-muldiv is too slow to use, so here added some value to get correct value.
local eeObj = getEEObject()
eeObj.AddHook(0x001ef6ec, 0x00000000, function()
				 eeObj.SetFpr(0, eeObj.GetFpr(0) + 0.00001)
end)
