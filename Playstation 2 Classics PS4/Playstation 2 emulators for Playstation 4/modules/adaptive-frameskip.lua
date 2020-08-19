-- Adaptive GS Frame Skipping

print("Loading Adaptive Frameskip module...")

local eeObj							= getEEObject()
local emuObj						= getEmuObject()
local eeOverlay 					= eeObj.getOverlayObject()
local gsObj							= getGsObject()
local gpr 							= require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

-- ----------------------------------------------------------------
-- Initialize performance parameters which are compatible with adaptive frameskipping.
-- If adaptive frameskipis not used then these must be set to much more aggressive values.

-- TODO: need to add parameter to control mpg data cycles calculation --jstine

local ApplyVifCycleSettings = function()

	if emuObj.IsNeoMode() then
		eeObj.Vu1MpgCycles(math.floor(125))
		eeObj.SetVifDataCycleScalar(1, 1.80)
	else
		eeObj.Vu1MpgCycles(math.floor(175))
		eeObj.SetVifDataCycleScalar(1, 2.6)
	end
end

ApplyVifCycleSettings()
-- ----------------------------------------------------------------

local frameskip = {}

frameskip.DeterministicMode = 0		-- set 0 for native (non-deterministic) behavior, see function frameskip.GetFramesInQueue()

-- constants:
local CLOCK_EE 				= 294912000.0
local CLOCK_EE_60hz 		= 294912000.0 / 60
local AdvanceCycleChunkSize = 16000
local ChunksPerFrame 		= (CLOCK_EE_60hz / AdvanceCycleChunkSize)
local TaperHoldBaseline		= ChunksPerFrame / 30				-- frames to hold even the smallest taper values
local TaperRatePerFrame		= ChunksPerFrame / 180				-- frames to taper away 1.0 worth of dog-ratio
local TaperHoldPerChunk		= 15.0 / ChunksPerFrame				-- hold for 15 frames per one frame of delay
local EnableTapering		= true

local MaxChunkCounter 		= math.floor(ChunksPerFrame * 2.50) -- warning: jaks can't frameskip past 2.0, they clamp ratio and slow down instead.

-- globals:
local isFrameDone 			= false
local m_counter 			= 0
local m_prev_framecount 	= 0
local m_taper_peak         	= 0
local m_taper_hold			= 0

-- Vars For diagnostic:
local d_truelog 			= false
local d_numframes 			= 0

frameskip.GetFramesInQueue = function()
	if frameskip.DeterministicMode == 0 then
		return gsObj.GetFramesInQueue()

	elseif frameskip.DeterministicMode == 1 then
		-- five regular frames, four slow frames
		local modulo = (eeObj.GetClock() // CLOCK_EE_60hz) % 9
		if modulo < 5 then
			return 0
		else
			return 3
		end

	elseif frameskip.DeterministicMode == 2 then
		-- nice slow cyclic test!
		local modulo = (eeObj.GetClock() // CLOCK_EE_60hz) % 240
		if modulo < 200 then
			return 0
		else
			return 3
		end

	elseif frameskip.DeterministicMode == 3 then
		-- slow cycle from 0 to 3 and back to 0, across about 10 seconds...
		local modulo = (eeObj.GetClock() // CLOCK_EE_60hz) % 600
		if modulo < 100 then
			return 0
		elseif modulo < 200 then
			return 1
		elseif modulo < 300 then
			return 2
		elseif modulo < 300 then
			return 3
		elseif modulo < 400 then
			return 2
		elseif modulo < 500 then
			return 1
		else
			return 0
		end
	end

	return gsObj.GetFramesInQueue()
end

frameskip.onFrameFinishedHook = function()
	emuObj.CountFrameOnPS2()	-- updates FRAPS/Actual FPS reading in olympus

	-- local cyl_data, cyl_mpg = eeObj.GetVif1Cycles()
	-- print (string.format("data=%6d  mpg=%6d", cyl_data, cyl_mpg))
	
	local frameCount 	 = frameskip.GetFramesInQueue()
	
	m_counter   = 0
	if frameCount ~= 0 or m_prev_framecount ~= 0 then
		-- Keep in mind here that the incurred cycle delay will be appended after the standard
		-- VIF/VU cycle delays.  Standard delays can be read using eeObj.GetVif1Cycles() as shown
		-- in a print snippet above.
		
		local fcnew   = frameCount
		local fcold   = m_prev_framecount

		-- first frame being a bit slow is often a red herring, because of how the deferred 
		-- EE/GS pipeline works.  So weight it very lightly here (if either fcold or fcnew is
		-- 0 then it'll go negative and help offset remaining 1.0)

		if fcnew < 1.2 then fcnew = fcnew - 0.6 end

		-- Delta from prev to new frame is used to indicate vectoring toward poor perf.
		--    eg. if prev was 1 and new is 3 then ramp up frameskip in a hurry (+2)

		local fcdelta = fcnew - fcold
		fcdelta = (fcdelta >= 0) and (fcdelta / 2.0) or 0

		m_counter  		= m_counter + (ChunksPerFrame /  7.5) * (fcnew + fcold + fcdelta)		-- baseline

		-- fcold and fcnew are squared and so to scale back the curve a bit we subtract some
		-- amount from them here:

		fcnew = fcnew - 0.25
		fcold = fcold - 0.40

		m_counter  		= m_counter + (ChunksPerFrame / 15.0) * (fcold * fcold)					-- weighted prev slowness
		m_counter  		= m_counter + (ChunksPerFrame /  9.0) * (fcnew * (fcnew+fcdelta))		-- weighted current slowness
		
		-- Boundscheck the counter.  Keep in mind that a counter delay of 2 frames will run at ~20fps.
		m_counter   = math.floor(m_counter)
		if m_counter > MaxChunkCounter then m_counter = MaxChunkCounter end
		
		if EnableTapering and m_taper_peak < m_counter then
			m_taper_hold = TaperHoldBaseline + (m_counter * TaperHoldPerChunk)
			m_taper_peak = m_counter
		end
	end

	-- Tapering kind of helps reduce the game's built-in jutter problem... but not really to the
	-- extent that I would like. -- jstine

	local m_origc = m_counter
	if m_counter < m_taper_peak then
		m_counter = math.floor(m_taper_peak)
	end
	
	--print (string.format("onFrameFinished! numFrames=%d,%d counter=%3d taper_hold=%5.1f taper_peak=%5.1f delayInFrames=%5.3f",
	--	m_prev_framecount, frameCount, m_origc, m_taper_hold, m_taper_peak, m_counter / ChunksPerFrame
	--));		

	if m_taper_peak > 0 then
		if m_taper_hold > 0 then
			m_taper_hold = m_taper_hold - 1
		elseif m_origc <= 25 then
			-- TODO make these constants?
			m_taper_peak = m_taper_peak - (m_taper_peak > 112 and TaperRatePerFrame or 0.75)
		end

		-- when taper is a large value, slide it back quickly regardless of hold state
		if m_taper_peak > 450 and m_taper_peak > m_origc then
			m_taper_peak = m_taper_peak * 0.90
		end
	end

	m_prev_framecount = frameCount
	isFrameDone = true		-- enables SpinWaitDelayHook
end

frameskip.SpinWaitDelayHook = function(hookpc, gprv, writeon)
	if not isFrameDone then
		return 
	end

	local numFrames = frameskip.GetFramesInQueue()
	local isSkipping = false
	
	--local numFrames = frameskip.GetFramesInQueue()
	--print (string.format("HOOKED @ 0x%02x - counter=%d numFrames=%d", hookpc, m_counter, numFrames))
	
	if m_counter > 0 then
		--if not d_truelog then
		--	print ( string.format("HOOKED! - numFrames=%d", numFrames))
		--	d_numframes = numFrames
		--end
		--d_truelog = true

		-- SetFrameSkipping call removed because it causes severe frame loss, due to internal scanout
		-- not aligning to when this hook is invoked.  The call was only implemented in order to solve
		-- interlace jitter problems on Jak TPL anyway, and isn't needed here... --jstine
		--gsObj.SetFrameSkipping(true)

		isSkipping = true
	end
	
	if isSkipping then
		--local v0 = eeObj.GetGpr(gprv)
		eeObj.SetGpr(gprv, writeon)
		eeObj.AdvanceClock(AdvanceCycleChunkSize)
		m_counter = m_counter - 1
		-- print ( string.format("SKIPP! - numFrames=%d", numFrames))
	else
		isFrameDone = false
		--gsObj.SetFrameSkipping(false)
		m_counter = 0

		--if d_truelog then
		--	print "BUSY ENDED, RESUMIMG..."
		--end
		--d_truelog = false
	end

	--if d_numframes ~= numFrames then
	--	print ( string.format("Frame Queue Changed - numFrames=%d", numFrames))
	--	d_numframes = numFrames
	--end
end

frameskip.InitHooks = function(display_frame_finish_addr, sceGsSyncPath_addr)
	-- 255c: F.GOAL_drawable__display_frame_finish:	// 'drawable__display-frame-finish'
	eeOverlay.AddPreHook("drawable.seg1", display_frame_finish_addr, 0x67BDFF80, frameskip.onFrameFinishedHook)

	-- 120838: +48	30420100 	andi	v0,v0,0x100
	-- 12083c:    	1440fffa 	bnez	v0,120828 <sceGsSyncPath+0x38>
	-- 120878: +88	30420100 	andi	v0,v0,0x100
	-- 12087c:    	1440fffa 	bnez	v0,120868 <sceGsSyncPath+0x78>

	-- 120850: +60	30630100 	andi	v1,v1,0x100
	-- 120854:    	1060000b 	beqz	v1,120884 <sceGsSyncPath+0x94>
	-- 12080c: +1c	30630100 	andi	v1,v1,0x100
	-- 120810:    	1060000c 	beqz	v1,120844 <sceGsSyncPath+0x54>

	eeObj.AddPreHook(sceGsSyncPath_addr + 0x48, 0x30420100, function() frameskip.SpinWaitDelayHook(0x48, gpr.v0, 0x100) end)
	eeObj.AddPreHook(sceGsSyncPath_addr + 0x88, 0x30420100, function() frameskip.SpinWaitDelayHook(0x88, gpr.v0, 0x100) end)
                                                                                                   
	eeObj.AddPreHook(sceGsSyncPath_addr + 0x1c, 0x30630100, function() frameskip.SpinWaitDelayHook(0x1c, gpr.v1, 0x100) end)
	eeObj.AddPreHook(sceGsSyncPath_addr + 0x60, 0x30630100, function() frameskip.SpinWaitDelayHook(0x60, gpr.v1, 0x100) end)

	-- these are hooks that block earlier than sceGsSyncPath (addresses are US region).
	-- Should be preferable to block in SyncPath tho -- just leaving these here as comments 'in case'  --jstine
	--eeObj.AddPreHook(0x00120A78, 0x00641824, function() SpinWaitDelayHook(gpr.v1, 0x03) end)
	--eeObj.AddPreHook(0x00120AA8, 0x00431024, function() SpinWaitDelayHook(gpr.v0, 0x03) end)
end

print("Adaptive Frameskip Module loaded!")

return frameskip
