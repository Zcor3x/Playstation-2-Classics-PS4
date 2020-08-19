-- Manhunt [US]

local gpr = require('ee-gpr-alias')

apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local emuObj = getEmuObject()	
local eeObj  = getEEObject()

-- Bug #9413
-- Disable uprender on the draw command which samples the framebuffer (0x3200) using bilinear sampling (texMode=2)
-- All lighting effects use TriFan prim type, so use that as well to filter against.
 
emuObj.SetGsTitleFix( "forceSimpleFetch",  "reserved", {prim=5, texMode=2, tbp=0x320000} )

-- Bug#9277
-- Shorten the timeout period for some particular execution command(s).
-- When entering the crane, some instruction is executed with a wait period of 0x7333.
-- Shortening the wait period to 0x4000 it.  Note that 0x5000 is enough to fix entering the
-- crane once, but a more aggressive value was needed for subsequent entry into the crane.

local FixBug9277 = function()
	local s0 = eeObj.GetGpr(gpr.s0)
	--local v0 = eeObj.GetGpr(gpr.v0)
	--print( string.format("-------- v0=0x%08x s0=0x%08x", v0, s0) )
	if s0 == 0x7333 then 
		eeObj.SetGpr(gpr.s0, 0x5800)
	end
end

-- No longer seems necessary, when FastForwardClock is applied here instead (see _cli.conf)
eeObj.AddHookJT(0x1d71f8, 0x10000036, FixBug9277)
