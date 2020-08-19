-- Lua 5.3
-- Title: Grand Theft Auto: Vice City - SLUS-20552 (USA) v3.00
-- Author: Nicola Salmoria
-- Date:   November 4, 2015


require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

apiRequest(0.7)	-- need widescreen support

local eeObj		= getEEObject()
local emuObj	= getEmuObject()


local USEWIDESCREEN_ADDRESS = 0x4ba7bc

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


local hook1 = eeObj.AddHook(0x279384, 0xffbf0000, H1)	-- <main>:
local hook2 = eeObj.AddHook(0x277784, 0x00000000, H2)	-- <TheGame(void)>:


-- Fix for bug #9161. The 'flying cars' cheat causes crashes when attempting to
-- fly an helicopter. We avoid that by disabling recognition of the cheat altogether.
-- The SLPM version comes with the cheat disabled out of the box.
eeInsnReplace(0x27db2c, 0x14400015, 0x10000015)	-- bnez -> b
