-- Lua 5.3
-- Title:   Destroy All Humans! PS2 - SLUS-20945 (USA)
-- Author:  Ernesto Corvi, Adam McInnis

-- Changelog:

apiRequest(0.7)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()
local gpr = require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

-- Widescreen
eeObj.AddHook(0x33C908, 0x3c0436c5, function() -- Graphics::Script::SetScreenRatio
	local mode = eeObj.GetGpr(gpr.v0)
	
--	print(string.format("mode: %08x", mode))
	
	if mode == 0x36c59d2b then -- widescreen
		emuObj.SetDisplayAspectWide()
	elseif mode == 0x855a87ef then -- standard
		emuObj.SetDisplayAspectNormal()
	end
end)

eeObj.AddHook(0x33ae1c, 0x0000282d, function() -- Graphics::Renderer::Renderer
	eeObj.SetGpr(gpr.a1, 2)
end)

eeObj.AddHook(0x34aa08, 0x27bdffc0, function() -- Graphics::RendererPs2::InitHardware
	eeObj.SetGpr(gpr.a1, 2) -- Put the game in NTSC mode (60 hz)
end)

emuObj.SetDisplayAspectWide()

-- CRC "settings.display.anamorphic" = 0x8b36afe9
-- $s2 = SaveType (1 = new save)

local overlay = InsnOverlay({
	0x27bdffe0, -- addiu $sp, -0x20
	0xffbf0010, -- sd $ra, 0x10($sp)
	0x0c059d02, -- memset
	0x00000000, -- nop
	0x24030001, -- li $v1, 1
	0x1472000b, -- bne $s2, $v1, +11
	0x00000000, -- nop
	0x0c09b3f0, -- jal UFO::Progress::Get(void)
	0x00000000, -- nop
	0x3c01bcf1, -- lui $at, 0x8b36
	0x34214d81, -- ori $at, $at, 0xafe9
	0xafa10000, -- sw $at, 0($sp)
	0x24030001, -- li $v1, 1
	0xa3a30004, -- sb $v1, 4($sp)
	0x03a0282d, -- move $a1, $sp
	0x0c09b84e, -- jal UFO::Progress::Record::AddKey(UFO::Progress::Content const&)
	0x0040202d, -- move $a0, $v0
	0xdfbf0010, -- ld $ra, 0x10($sp)
	0x03e00008, -- jr $ra
	0x27bd0020  -- addiu $sp, 0x20
})
local call_overlay = 0x0c000000 | (overlay >> 2)
eeInsnReplace(0x271A90, 0x0c059d02, call_overlay) -- UFO::Progress::Storage::PrepareWrite

-- Disable Progressive Scan and Adjust Screen Position

local overlay2 = InsnOverlay({
	0x27bdfff0, -- addiu $sp, -0x10
	0xffbf0000, -- sd $ra, 0(sp)
	0xffb00008, -- sd $s0, 8(sp)
	0x3c05000f, -- lui $a1, 0x000f
	0x34a57000, -- ori $a1, 0x7000
	0x0c0db834, -- jal Script::State::DoString
	0x0080802d, -- move $s0, $a0
	0x24050001, -- li $a1, 1
	0x0c0db9c8, -- jal Script::State::IsNull(int)
	0x0200202d, -- move $a0, $s0
	0xdfb00008, -- ld $s0, 8(sp)
	0xdfbf0000, -- ld $ra, 0(sp)
	0x03e00008, -- jr ra
	0x27bd0010  -- addiu $sp, 0x10
})
local call_overlay2 = 0x0c000000 | (overlay2 >> 2)
eeInsnReplace(0x2e594c, 0x0c0db9c8, call_overlay2) -- Sim::Manager::ProcessScript near Sim::Manager::SetPauseFlag

eeObj.AddHook(0x2e5948, 0x0240202d, function() -- Sim::Manager::ProcessScript near Sim::Manager::SetPauseFlag
	local luaString = [[
-- disable progressive scan and adjust screen
gui.i.SMOptionsDisplay.table.slots[3] = nil
gui.i.SMOptionsDisplay.table.slots[4] = nil
]]
	eeObj.WriteMemStrZ(0xf7000, luaString)
end)
