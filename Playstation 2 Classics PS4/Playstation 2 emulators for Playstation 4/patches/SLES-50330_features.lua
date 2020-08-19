-- Lua 5.3
-- Title:  Grand Theft Auto III - SLES-50330 (Europe) v1.60
-- Author: Nicola Salmoria
-- Date:   November 3, 2015


require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

apiRequest(0.7)	-- need widescreen support

local eeObj		= getEEObject()
local emuObj	= getEmuObject()


local USEWIDESCREEN_ADDRESS = 0x417c4c

local H1 =	-- start of main()
	function()
		eeObj.WriteMem8(USEWIDESCREEN_ADDRESS, 1)	-- enable widescreen
	end

local H2 =	-- change widescreen flag
	function()
		local isWidescreen = eeObj.GetGpr(gpr.v0)
		
		if isWidescreen == 0 then
			emuObj.SetDisplayAspectNormal()
		else
			emuObj.SetDisplayAspectWide()
		end
	end

local hook1 = eeObj.AddHook(0x27fa64, 0x7fbf0000, H1)	-- <main>:
local hook2 = eeObj.AddHook(0x271010, 0xa382b8dc, H2)	-- <CMenuManager::AnaliseMenuContents(void)>:
