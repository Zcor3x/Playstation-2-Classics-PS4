require("ee-gpr-alias")
apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

-- Bug#8907. accuracy-muldiv is too slow to use, so here added some value to get correct value.
local eeObj = getEEObject()
eeObj.AddHook(0x001ef6ec, 0x00000000, function()
				 eeObj.SetFpr(0, eeObj.GetFpr(0) + 0.00001)
end)
