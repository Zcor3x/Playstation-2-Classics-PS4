-- Lua 5.3
-- Title:   Fahrenheit PS2 - SLES-53539 (EUR)
-- Author:  Ernesto Corvi, Adam McInnis

-- Changelog:

require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])
require( "ee-cpr0-alias" ) -- for EE CPR

apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()

local L1 = function() -- QDT::SINT::SCRIPT_LOADING_SCREEN::EM::Run
	emuObj.ThrottleMax()
end
	
local L2 = function() -- QDT::SINT::SCRIPT_LOADING_SCREEN::EM::Stop
	emuObj.ThrottleNorm()
end
	
local load1 = eeObj.AddHook(0x387040, 0x3c02004b, L1) -- QDT::SINT::SCRIPT_LOADING_SCREEN::Run
local load2 = eeObj.AddHook(0x387090, 0x3c02004b, L2) -- QDT::SINT::SCRIPT_LOADING_SCREEN::Stop

-- Widescreen
eeInsnReplace(0x20a7c0, 0x3c013faa, 0x3c013fe3)
eeInsnReplace(0x20a7c4, 0x3421aaab, 0x34218e39)
emuObj.SetDisplayAspectWide()

-- Skip video mode options
local videomenuVM = { 0x04, 0x01, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00,
					  0x3B, 0x0D, 0x00, 0x00, 0x3B, 0x0B, 0x00, 0x00,
					  0x3B, 0x26, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 }
					  
local visualmenuVM = { 0x04, 0x01, 0x00, 0x00, 0xA2, 0x00, 0x00, 0x00,
					   0x3B, 0x19, 0x00, 0x00, 0x3B, 0x18, 0x00, 0x00 }

-- locates src chunk on (dst,cnt). -1 if not found, offset if found
local locateChunk = function(src, dst, count)
	local offs = -1
	
	for x = 0, count - #src do
		if eeObj.ReadMem8(dst+x) == src[1] then
			local found = true
			for y = 1, #src do
				if eeObj.ReadMem8(dst+x+y-1) ~= src[y] then
					found = false
					break
				end
			end
				
			if found == true then
				offs = x
				break
			end
		end
	end
	
	return offs
end

eeObj.AddHook(0x2812b0, 0x27bdfff0, function() -- QDT::VM::BYTE_CODE::BYTE_CODE
	local obj = eeObj.GetGpr(gpr.a1)
	local bytecode = eeObj.ReadMem32(obj+0x18)
	local count = eeObj.ReadMem32(obj+0x20)
	
	if count > #videomenuVM then
		local offs = locateChunk(videomenuVM, bytecode, count)
		if offs >= 0 then
			print("Skipping video mode menu")
			eeObj.WriteMem8(bytecode+offs+4, 8) -- beq 0x44 -> beq 0x8
		end
	end
	
	if count > #visualmenuVM then
		local offs = locateChunk(visualmenuVM, bytecode, count)
		if offs >= 0 then
			print("Skipping visual mode video menu")
			eeObj.WriteMem8(bytecode+offs+1, 2) -- beq 0xa2 -> bne 0xa2
		end
	end
end)

-- Force 60hz
eeInsnReplace(0x207ae0, 0x00a0802d, 0x24100001) -- move $s0, $a1 -> li $s0, 1

-- Fix for bug 9716, which is a bug in the game.
-- Trying to retrieve a COM handle in the game will cause an infinite
-- loop if the handle has been deallocated and the debug server is not
-- connected. There's apparently a small race condition in the Asylum
-- level that sometimes can trigger the bug.
-- The fix involves getting out of the loop.
-- It causes a small visual glitch but otherwise the game continues to work fine.

eeInsnReplace(0x1c5958, 0x10400005, 0) -- QDT::KCOM::COM_SERVICE::RetrieveComHandle
eeInsnReplace(0x1c5b6c, 0x10400005, 0) -- QDT::KCOM::COM_SERVICE::RetrieveComHandle
eeInsnReplace(0x1c5d24, 0x10400005, 0) -- QDT::KCOM::COM_SERVICE::RetrieveComHandle
