-- Lua 5.3
-- Title:   Destroy All Humans! PS2 - SLUS-20945 (USA)
-- Author:  Ernesto Corvi, Adam McInnis

-- Changelog:

apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()
local gpr = require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

-- Widescreen
eeObj.AddHook(0x308270, 0x3c0336c5, function() -- Graphics::Script::SetScreenRatio
	local mode = eeObj.GetGpr(gpr.v0)
	
--	print(string.format("mode: %08x", mode))
	
	if mode == 0x36c59d2b then -- widescreen
		emuObj.SetDisplayAspectWide()
	elseif mode == 0x855a87ef then -- standard
		emuObj.SetDisplayAspectNormal()
	end
end)

eeObj.AddHook(0x3078F4, 0xae0000f4, function() -- Graphics::Renderer::Renderer
	local renderer = eeObj.GetGpr(gpr.s0)
	eeObj.WriteMemFloat(renderer+0x200, 1.3333333)
	eeObj.WriteMemFloat(renderer+0x204, 1.7777777)
	eeObj.WriteMem32(renderer+0x208, 2)
end)

emuObj.SetDisplayAspectWide()

-- CRC "settings.display.widescreen" = 0xbcf14d81
-- $s2 = SaveType (1 = new save)

local overlay = InsnOverlay({
	0x27bdffe0, -- addiu $sp, -0x20
	0xffbf0010, -- sd $ra, 0x10($sp)
	0x0c0d49d8, -- jal Core::Memset(void *,int,uint)
	0x00000000, -- nop
	0x24030001, -- li $v1, 1
	0x1472000b, -- bne $s2, $v1, +11
	0x00000000, -- nop
	0x0c09dacc, -- jal UFO::Progress::Get(void)
	0x00000000, -- nop
	0x3c01bcf1, -- lui $at, 0xbcf1
	0x34214d81, -- ori $at, $at, 0x4d81
	0xafa10000, -- sw $at, 0($sp)
	0x24030001, -- li $v1, 1
	0xa3a30004, -- sb $v1, 4($sp)
	0x03a0282d, -- move $a1, $sp
	0x0c09dd4c, -- jal UFO::Progress::Record::AddKey(UFO::Progress::Content const&)
	0x0040202d, -- move $a0, $v0
	0xdfbf0010, -- ld $ra, 0x10($sp)
	0x03e00008, -- jr $ra
	0x27bd0020  -- addiu $sp, 0x20
})
local call_overlay = 0x0c000000 | (overlay >> 2)
eeInsnReplace(0x2789F8, 0x0c0d49d8, call_overlay) -- UFO::Progress::Storage::PrepareWrite
