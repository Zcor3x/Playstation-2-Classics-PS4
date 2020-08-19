require("ee-gpr-alias")
apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

eeObj = getEEObject()

-- Bug#8968 (see bugzilla for details)
-- There is a bug which causes a hang (even on a real PS2) when the Boost fish stat goes above 100.
-- We intercept when the infinite loop would happen, and force it to end.
local PatchFish =
	function()
		local t0 = eeObj.GetGpr(gpr.t0)
		local t4 = eeObj.GetGpr(gpr.t4)
		local stat = eeObj.GetGpr(gpr.v1)
		if t0 == t4 and stat > 100 then	-- infinite loop
			eeObj.SetGpr(gpr.v1, 100)
		end
	end

eeObj.AddHook(0x19acec, 0x2463ffff, PatchFish)	-- <CGameDataUsed::CheckParamLimmit(void)>
