-- Lua 5.3
-- Title: Grand Theft Auto: Vice City - SLES-51061 (Europe) v4.00
-- Author: Nicola Salmoria
-- Date:   November 4, 2015


require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

apiRequest(0.7)	-- need widescreen support

local eeObj		= getEEObject()
local emuObj	= getEmuObject()


local USEWIDESCREEN_ADDRESS = 0x4bb9b8

local H1 =	-- start of main()
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


local hook1 = eeObj.AddHook(0x27a724, 0xffbf0000, H1)	-- <main>:
local hook2 = eeObj.AddHook(0x2784a4, 0x00000000, H2)	-- <TheGame(void)>:


-- Fix for bug #9161. The 'flying cars' cheat causes crashes when attempting to
-- fly an helicopter. We avoid that by disabling recognition of the cheat altogether.
-- The SLPM version comes with the cheat disabled out of the box.
eeInsnReplace(0x27e93c, 0x14400015, 0x10000015)	-- bnez -> b
