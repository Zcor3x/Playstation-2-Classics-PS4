-- Lua 5.3
-- Title: Grand Theft Auto: San Andreas - SLUS-20946 (USA) v3.00
-- Author: Nicola Salmoria
-- Date:   November 5, 2015


require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

apiRequest(0.7)	-- need widescreen support

local eeObj		= getEEObject()
local emuObj	= getEmuObject()


local USEWIDESCREEN_ADDRESS = 0x7004ef

local H1 =	-- init widescreen flag
	function()
		eeObj.WriteMem8(USEWIDESCREEN_ADDRESS, 1)	-- enable widescreen
	end

local H2 =	-- main game loop
	function()
		local isWidescreen = eeObj.ReadMem8(USEWIDESCREEN_ADDRESS)
		
		if isWidescreen == 0 then
			emuObj.SetDisplayAspectNormal()
		else
			emuObj.SetDisplayAspectWide()
		end
	end


local hook1 = eeObj.AddHook(0x233584, 0xa200004f, H1)	-- <CMenuManager::__ct(void)>:
local hook2 = eeObj.AddHook(0x246750, 0x24040012, H2)	-- <TheGame(void)>:
