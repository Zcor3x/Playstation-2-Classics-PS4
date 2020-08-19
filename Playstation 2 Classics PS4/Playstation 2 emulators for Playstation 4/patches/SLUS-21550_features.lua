-- Lua 5.3
-- Title:   Metal Slug Anthology PS2 - SLUS-21550 (USA)
-- Author:  Ernesto Corvi, Adam McInnis

-- Changelog:
-- v1.1: Added fix for black screen launching executables
-- v1.2: Simplified hook code
-- v1.3: Added video mode hooks
-- v1.5: Now using predicate hooks
-- v1.8: Added Volume scaling
-- v1.9: Added PS3 fight stick support. Replaced SNK logo. TGL
-- v2.0: Fixed bug 9690. Removed Playmore logo from MS6 boot. Accellerated s'more loading. TGL
-- v2.1: Added Volume scaling for intro movie
-- v2.2: Redid Volume scaling for intro movie

apiRequest(1.2) -- request version 1.2 API. Calling apiRequest() is mandatory.

local eeObj  		= getEEObject()
local emuObj		= getEmuObject()

local gpr = require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])
local kFilterMode, kWrapMode, kBlendMultiplier, kBlendFunc = require("sprite")
local PadConnectType = require("pad-connect-type")

HIDPad_Enable()

local vsync_timer = 0
local snklogo = 0
local fname = ''

local L1 = function()
	emuObj.ThrottleMax()
end
	
local L2 = function()
	emuObj.ThrottleNorm()
end

-- Fix for black screen booting an elf. This is a game bug.
-- The v1.0 of the game suffered from an intermittent bug on the real PS2
-- where sometimes it would hang on a black screen trying to launch a new elf.
-- This is apparently due to a bad IOP state, which caused sceCdInit to hang.
-- Later versions of the game (1.1, 1.2) attempted to fix this in different ways.
-- On Olympus, v1.0 (USA) hangs always, while v1.2 (EUR/JPN) works always.
-- The fix implemented here replaces a call to FlushCache() to loadImageAndReboot(),
-- which is a function that reboots the IOP and resolves the hang.

eeInsnReplace(0x189c24, 0x0c08f7f8, 0x0c061dd2) -- FlushCache() -> loadImageAndReboot()
eeInsnReplace(0x117804, 0x0c0c1e08, 0x0c045e20) -- FlushCache() -> loadImageAndReboot()

----------------------------------------------------------------------
-- Sound Volume scaling

local volumeScale = 0.75
local movieScale = 0.6

----------------------------------------------------------------------
-- Video Mode Hooks
--
-- The following patches embed a Video Options setting in the Options menu of the game
--

local SaveData = emuObj.LoadConfig(0)

if not next(SaveData) then
	SaveData.videomode  = 0
end

local sprite0 = getSpriteObject(0)
local sprite1 = getSpriteObject(1)
local sprite2 = getSpriteObject(2)
local sprite3 = getSpriteObject(3)

-- Notifications should be assigned to two unused sprite slots.  Since we want them to
-- be displayed on top of everything else, they should be the highest sprites in the list.
local spr_p1_notify = getSpriteObject(4)
local spr_p2_notify = getSpriteObject(5)
local spr_p1d_notify = getSpriteObject(6)
local spr_p2d_notify = getSpriteObject(7)

-- note: Texture 0 is fixed as the PS2 scanout.
local texture1 = getTextureObject(1)
local texture2 = getTextureObject(2)
local texture3 = getTextureObject(3)
local texture4 = getTextureObject(4)
local texture5 = getTextureObject(5)
local texture6 = getTextureObject(6)
local texture7 = getTextureObject(7)
local texture8 = getTextureObject(8)

-- ------------------------------------------------------------
local STATE_STOPPED		= 0
local STATE_RUNNING		= 1

local notify_ypos = 24
local notify_p1_xsize = 0
local notify_p2_xsize = 0
local notify_p1d_xsize = 0
local notify_p2d_xsize = 0
local notify_ysize = 0

local notify_frames_p1 = 0
local notify_frames_p2 = 0
local notify_animstate_p1 = STATE_STOPPED
local notify_animstate_p2 = STATE_STOPPED

local connected_p1 = 47
local connected_p2 = 47
local blink_on_p1 = true
local blink_on_p2 = true

-- ---------------------------------------------------
-- the global function 'Global_InitGpuResources()' is invoked by the emulator after
-- the GS has been initialized.  Textures and Shaders must be loaded here.
--
Global_InitGpuResources = function()
	-- # Fragment Shader 0 is fixed as the default no-thrills as-is renderer.
	emuObj.LoadFsShader(1, "./shader_scanlines_any.sb")		-- (1) = Scanlines for SNK logo
	emuObj.LoadFsShader(2, "./shader_SL480_p.sb")		-- (2) = 480P ScanLine Sim
	texture1.Load("./ART1.png")
	texture2.Load("./ART2.png")
	texture3.Load("./SNK_LOGO.png")
	texture4.Load("./p1.png")
	texture5.Load("./p2.png")
	texture6.Load("./p1d.png")
	texture7.Load("./p2d.png")
	texture8.Load("./SNK_LOGO_sl.png")

	local p1_w,p1_h = texture4.GetSize()
	local p2_w,p2_h = texture5.GetSize()
	local p1d_w,p1d_h = texture6.GetSize()
	local p2d_w,p2d_h = texture7.GetSize()
	
	notify_p1_xsize = p1_w
	notify_p2_xsize = p2_w
	notify_p1d_xsize = p1d_w
	notify_p2d_xsize = p2d_w
	notify_ysize = p1_h

	spr_p1_notify.BindTexture(4)
	spr_p1_notify.SetPosXY(-1 - notify_p1_xsize, notify_ypos)   -- default position is fully obscured from view
    spr_p1_notify.SetSizeXY(p1_w,p1_h)
	spr_p1_notify.SetPosUV(0,0)
    spr_p1_notify.SetSizeUV(p1_w,p1_h)
	spr_p1_notify.SetBlendColorEquation(blendDefaultEquation)

	spr_p2_notify.BindTexture(5)
	spr_p2_notify.SetPosXY(-1 - notify_p2_xsize, notify_ypos)   -- default position is fully obscured from view
    spr_p2_notify.SetSizeXY(p2_w,p1_h)
	spr_p2_notify.SetPosUV(0,0)
    spr_p2_notify.SetSizeUV(p2_w,p1_h)
	spr_p2_notify.SetBlendColorEquation(blendDefaultEquation)

	spr_p1d_notify.BindTexture(6)
	spr_p1d_notify.SetPosXY(-1 - notify_p1d_xsize, notify_ypos)   -- default position is fully obscured from view
    spr_p1d_notify.SetSizeXY(p1d_w,p1_h)
	spr_p1d_notify.SetPosUV(0,0)
    spr_p1d_notify.SetSizeUV(p1d_w,p1_h)
	spr_p1d_notify.SetBlendColorEquation(blendDefaultEquation)

	spr_p2d_notify.BindTexture(7)
	spr_p2d_notify.SetPosXY(-1 - notify_p2d_xsize, notify_ypos)   -- default position is fully obscured from view
    spr_p2d_notify.SetSizeXY(p2d_w,p1_h)
	spr_p2d_notify.SetPosUV(0,0)
    spr_p2d_notify.SetSizeUV(p2d_w,p1_h)
	spr_p2d_notify.SetBlendColorEquation(blendDefaultEquation)
end

local update_notifications_p1 = function()

	if notify_animstate_p1 == STATE_STOPPED then 
		spr_p1_notify.Disable()
		spr_p1d_notify.Disable()
		return
	end

	L2()

	local keyframe = 15

	notify_frames_p1 = notify_frames_p1 + 1

	if math.ceil(notify_frames_p1/keyframe) == notify_frames_p1/keyframe then blink_on_p1 = not blink_on_p1 end
	if blink_on_p1 == true then notify_ypos = 24 end
	if blink_on_p1 == false then notify_ypos = -84 end

--	print(string.format("rounded %s, floating %s, blink %s ypos %s", math.ceil(notify_frames_p1/keyframe), notify_frames_p1/keyframe, blink_on_p1, notify_ypos))
--	print(string.format("notify_frames_p1 %s", notify_frames_p1))

	if notify_frames_p1 >= 225 then
		notify_animstate_p1 = STATE_STOPPED
		notify_frames_p1 = 0
		connected_p1 = 47
	end

	if connected_p1 == true then
		spr_p1_notify.SetBlendColor(1.0,1.0,1.0,1.0)
		spr_p1_notify.SetPosXY(math.floor((1920-notify_p1_xsize)/2), notify_ypos)
		spr_p1_notify.Enable()
	end

	if connected_p1 == false then
		spr_p1d_notify.SetBlendColor(1.0,1.0,1.0,1.0)
		spr_p1d_notify.SetPosXY(math.floor((1920-notify_p1d_xsize)/2), notify_ypos)
		spr_p1d_notify.Enable()
	end
end

local update_notifications_p2 = function()

	if notify_animstate_p2 == STATE_STOPPED then 
		spr_p2_notify.Disable()
		spr_p2d_notify.Disable()
		return
	end

	L2()

	local keyframe = 15

	notify_frames_p2 = notify_frames_p2 + 1

	if math.ceil(notify_frames_p2/keyframe) == notify_frames_p2/keyframe then blink_on_p2 = not blink_on_p2 end
	if blink_on_p2 == true then notify_ypos = 24 + notify_ysize + 8 end
	if blink_on_p2 == false then notify_ypos = -84 - notify_ysize - 8 end

--	print(string.format("rounded %s, floating %s, blink %s ypos %s", math.ceil(notify_frames_p2/keyframe), notify_frames_p2/keyframe, blink_on_p2, notify_ypos))

	if notify_frames_p2 >= 225 then
		notify_animstate_p2 = STATE_STOPPED
		notify_frames_p2 = 0
		connected_p2 = 47
	end

--	print(string.format("connected_p1 %s, connected_p2 %s", connected_p1, connected_p2))

	if connected_p2 == true then
		spr_p2_notify.SetBlendColor(1.0,1.0,1.0,1.0)
		spr_p2_notify.SetPosXY(math.floor((1920-notify_p2_xsize)/2), notify_ypos)
		spr_p2_notify.Enable()
	end

	if connected_p2 == false then
		spr_p2d_notify.SetBlendColor(1.0,1.0,1.0,1.0)
		spr_p2d_notify.SetPosXY(math.floor((1920-notify_p2d_xsize)/2), notify_ypos)
		spr_p2d_notify.Enable()
	end

end

-- slot can range from 0 to 3, for users 1 thru 4.
-- pad_type can be either:  DS4, REMOTE_DS4, REMOTE_VITA, or HID
local onHIDPadEvent = function(slot, connected, pad_type)
	spr_p1_notify.Disable()
	spr_p1d_notify.Disable()
	spr_p2_notify.Disable()
	spr_p2d_notify.Disable()
--	print(string.format("slot %s, connected %s, pad_type %s", slot, connected, pad_type))
	if pad_type == PadConnectType.HID then
		notify_frames_p1 = 0
		notify_frames_p2 = 0
		blink_on_p1 = true
		blink_on_p2 = true
		if slot == 0 then 
			connected_p1 = connected
			notify_animstate_p1 = STATE_RUNNING
		end
		if slot == 1 then 
			connected_p2 = connected 
			notify_animstate_p2 = STATE_RUNNING
		end
	end
end

local scanlineParams = {
	240.0,      -- float scanlineCount
	0.7,        -- float scanlineHeight;
	1.5,        -- float scanlineBrightScale;
	0.5,        -- float scanlineAlpha;
	0.5         -- float vignetteStrength;
}

-- ---------------------------------------------------
-- Full Screen (480p) NoFX
-- ---------------------------------------------------

local original = function()
	if snklogo == 1 then
		sprite0.BindTexture(3)
		sprite0.SetPosXY(0,0)
		sprite0.SetSizeXY(1920,1080)
		sprite0.SetPosUV(0,0)
		sprite0.SetSizeUV(1920,1080)
	else
		sprite0.BindTexture(0)
		sprite0.BindFragmentShader(0)
		sprite0.SetPosXY((1920-1440)/2,0)
		sprite0.SetSizeXY(1440,1080)
	end
	sprite0.Enable()
	sprite1.Disable()
end

-- ---------------------------------------------------
-- Full Screen + ScanLines (480p)
-- ---------------------------------------------------

local scanlines = function()
	if snklogo == 1 then
		sprite0.BindTexture(8)
		sprite0.SetPosXY(0,0)
		sprite0.SetSizeXY(1920,1080)
		sprite0.SetPosUV(0,0)
		sprite0.SetSizeUV(1920,1080)
		sprite0.BindFragmentShader(1)
		sprite0.SetShaderParams(scanlineParams)
	else sprite0.BindTexture(0)
		sprite0.SetPosXY((1920-1440)/2,0)
		sprite0.SetSizeXY(1440,1080)
		sprite0.BindFragmentShader(2)
		sprite0.SetShaderParams(scanlineParams)
	end
	sprite0.Enable()
	sprite1.Disable()
end

-- ---------------------------------------------------
-- SNK Overlay NoFX
-- ---------------------------------------------------
local bezel = function()
	if snklogo == 1 then
		sprite0.BindTexture(3)
		sprite0.SetPosXY(0,0)
		sprite0.SetSizeXY(1920,1080)
		sprite0.SetPosUV(0,0)
		sprite0.SetSizeUV(1920,1080)
	else sprite0.BindTexture(0)
		sprite0.BindFragmentShader(0)
		sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
		sprite0.SetSizeXY(1280,896)
	end
	sprite0.Enable()

	sprite1.BindTexture(1)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end

-- ---------------------------------------------------
-- SNK Overlay + ScanLines (480p)
-- ---------------------------------------------------

local bezel_scanlines = function()
	if snklogo == 1 then
		sprite0.BindTexture(8)
		sprite0.SetPosXY(0,0)
		sprite0.SetSizeXY(1920,1080)
		sprite0.SetPosUV(0,0)
		sprite0.SetSizeUV(1920,1080)
		sprite0.BindFragmentShader(1)
		sprite0.SetShaderParams(scanlineParams)
	else sprite0.BindTexture(0)
		sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
		sprite0.SetSizeXY(1280,896)
		sprite0.BindFragmentShader(2)
		sprite0.SetShaderParams(scanlineParams)
	end
	sprite0.Enable()

	sprite1.BindTexture(1)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end

-- ---------------------------------------------------
-- Arcade Overlay NoFX
-- ---------------------------------------------------
local bezel2 = function()
	if snklogo == 1 then
		sprite0.BindTexture(3)
		sprite0.SetPosXY(0,0)
		sprite0.SetSizeXY(1920,1080)
		sprite0.SetPosUV(0,0)
		sprite0.SetSizeUV(1920,1080)
	else sprite0.BindTexture(0)
		sprite0.BindFragmentShader(0)
		sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
		sprite0.SetSizeXY(1280,896)
	end
	sprite0.Enable()

	sprite1.BindTexture(2)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end

-- ---------------------------------------------------
-- Arcade Overlay + ScanLines (480p)
-- ---------------------------------------------------

local bezel2_scanlines = function()
	if snklogo == 1 then
		sprite0.BindTexture(8)
		sprite0.SetPosXY(0,0)
		sprite0.SetSizeXY(1920,1080)
		sprite0.SetPosUV(0,0)
		sprite0.SetSizeUV(1920,1080)
		sprite0.BindFragmentShader(1)
		sprite0.SetShaderParams(scanlineParams)
	else sprite0.BindTexture(0)
		sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
		sprite0.SetSizeXY(1280,896)
		sprite0.BindFragmentShader(2)
		sprite0.SetShaderParams(scanlineParams)
	end
	sprite0.Enable()

	sprite1.BindTexture(2)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end

local vidmodes = { "Original", "Scanlines", "Art1", "Art1 + Scanlines", "Art2", "Art2 + Scanlines"}

local function switchVideoMode(index)
--	print(string.format("video mode: %d", index))
	
	if index == 0 then
		original()
	elseif index == 1 then
		scanlines()
	elseif index == 2 then
		bezel()
	elseif index == 3 then
		bezel_scanlines()
	elseif index == 4 then
		bezel2()
	elseif index == 5 then
		bezel2_scanlines()
	end

	if index ~= SaveData.videomode then
		SaveData.videomode = index
		emuObj.SaveConfig(0, SaveData)
	end
end

----------------------------------------------------------------------
--  Video Menu injection code
----------------------------------------------------------------------
local curvideomode = SaveData.videomode
local videomenu_count = #vidmodes
local cvideomode_addr = 0xf7000
local cvideomode_settings_addr = cvideomode_addr + 0x20
local cvideomenu_alloc_size = 0xd8 + (videomenu_count * 0x19c) + (videomenu_count * 0x184) + 0x184 + 4
local cvideomenu_items_offs = 0xd8 + (videomenu_count * 0x19c)
local cvideomenu_title_offs = 0xd8 + (videomenu_count * 0x19c) + (videomenu_count * 0x184)
local cvideomenu_sel_offs = 0xd8 + (videomenu_count * 0x19c) + (videomenu_count * 0x184) + 0x184
local optionsmenu_count = 5
local coptionsmenu_items_offs = 0xd8 + (optionsmenu_count * 0x19c)
local coptionsmenu_title_offs = 0xd8 + (optionsmenu_count * 0x19c) + (optionsmenu_count * 0x184)
local coptionsmenu_sel_offs = 0xd8 + (optionsmenu_count * 0x19c) + (optionsmenu_count * 0x184) + 0x184

local coptionsmenu_code = InsnOverlay({
	0x27bdffe0, -- addiu $sp, -0x20
	0xffbf0000, -- sd $ra, 0x00($sp)
	0x0c0625e6, -- jal CMessage::setText(char const *)
	0xffb00010, -- sd $s0, 0x10($sp)
	0x26a405ac, -- addiu $a0, $s5, 0x5ac
	0x3c050000 | (cvideomode_addr >> 16), -- lui $a1, (cvideomode_addr >> 16)
	0x24a50000 | (cvideomode_addr & 0xffff), -- addiu $a1, $a1, (cvideomode_addr & 0xffff)
	0x0c0625e6, -- jal CMessage::setText(char const *)
	0x00a0802d, -- move $s0, $a1
	0x0c079e28, -- jal messageLookup(char const *)
	0x0200202d, -- move $a0, $s0
	0x26a40d70, -- addiu $a0, $s5, 0xd70
	0x0c0625e6, -- jal CMessage::setText(char const *)
	0x0040282d, -- move $a1, $v0
	0xdfb00010, -- ld $s0, 0x10($sp)
	0xdfbf0000, -- ld $ra, 0x00($sp)
	0x03e00008, -- jr $ra
	0x27bd0020  -- addiu $sp, 0x20
})
local coptionsmenu_call = 0x0c000000 | (coptionsmenu_code >> 2)

local cvideomenu_alloc_code = InsnOverlay({
	0x27bdfff0, -- addiu $sp, -0x10
	0xffbf0000, -- sd $ra, 0x00($sp)
	0x24020001, -- li $v0, 1
	0x10620009, -- beq $v0, $v1, label1
	0x27ff000c, -- addiu $ra, $ra, 0x0c
	0xffbf0000, -- sd $ra, 0x00($sp)
	0x0c081e2a, -- label1: jal __builtin_new
	0x24040000 | cvideomenu_alloc_size, -- li $a0, videomenu_alloc
	0x0040902d, -- move $s2, $v0
	0x0c071b38, -- jal CNetworkMenu:CNetworkMenu
	0x0240202d, -- move $a0, $s2
	0x10000003, -- b label2
	0x00000000, -- nop
	0x0c081e2a, -- label1: jal __builtin_new
	0x00000000, -- nop
	0xdfbf0000, -- label2: ld $ra, 0x00($sp)
	0x03e00008, -- jr $ra
	0x27bd0010  -- addiu $sp, 0x10
})
local cvideomenu_alloc_call = 0x0c000000 | (cvideomenu_alloc_code >> 2)

local cvideomenu_code = InsnOverlay({
	0x27bdfff0, -- addiu $sp, -0x10
	0x27ff0068, -- addiu $ra, $ra, 0x68
	0xffbf0000, -- sd $ra, 0x00($sp)
	0x24100000 | videomenu_count, -- li $s0, videomenu_count
	0x3c110000 | (cvideomode_settings_addr >> 16), -- lui $s1, (cvideomode_settings_addr >> 16)
	0x26310000 | (cvideomode_settings_addr & 0xffff), -- addiu $s1, $s1, (cvideomode_settings_addr >> 16)
	0x03c09025, -- move $s2, $fp
	
	-- label1
	0x0240202d, -- move $a0, $s2
	0x0c0625e6, -- jal CMessage::setText(char const *)
	0x0220282d, -- move $a1, $s1
	0x2610ffff, -- addiu $s0, -1
	0x2652019c, -- addiu $s2, $s2, 0x19c
	0x1600fffa, -- bnez  $s0, label1
	0x26310020, -- addiu $s1, $s1, 0x20
	
	0x24100000 | videomenu_count, -- li $s0, videomenu_count
	0x3c110000 | (cvideomode_settings_addr >> 16), -- lui $s1, (cvideomode_settings_addr >> 16)
	0x26310000 | (cvideomode_settings_addr & 0xffff), -- addiu $s1, $s1, (cvideomode_settings_addr >> 16)
	
	-- label2
	0x0c079e28, -- jal messageLookup(char const *)
	0x0220202d, -- move $a0, $s1
	0x0040282d, -- move $a1, $v0
	0x0c0625e6, -- jal CMessage::setText(char const *)
	0x0240202d, -- move $a0, $s2
	0x2610ffff, -- addiu $s0, -1
	0x26520184, -- addiu $s2, $s2, 0x184
	0x1600fff8, -- bnez  $s0, label2
	0x26310020, -- addiu $s1, $s1, 0x20
	
	0x3c17002a, -- lui $s7, 0x2A
	0x3c014228,	-- lui $at, 0x4228
	0x4481a800,	-- mtc1 $at, f21
	0x24150000 | (videomenu_count - 1), -- li $s5, (videomenu_count - 1)
	0X269300d8, -- addiu $s3, $s4, 0xd8
	
	0xdfbf0000, -- ld $ra, 0x00($sp)
	0x03e00008, -- jr $ra
	0x27bd0010  -- addiu $sp, 0x10
})
local cvideomenu_call = 0x0c000000 | (cvideomenu_code >> 2)

-- CNetworkMenu::CNetworkMenu
eeInsnReplace(0x1c6d00, 0x24110002, 0x24110000 | (videomenu_count - 1)) -- li $s1, 2 -> li $s1, videomenu_count - 1
eeInsnReplace(0x1c6d88, 0x269605ac, 0x26960000 | cvideomenu_items_offs) -- addiu $s6, $s4, 0x5ac -> addiu $s6, $s4, cvideomenu_items_offs
eeInsnReplace(0x1c6d8c, 0x24110002, 0x24110000 | (videomenu_count - 1)) -- li $s1, 2 -> li $s1, videomenu_count - 1
eeInsnReplace(0x1c6db4, 0x26820a38, 0x26820000 | cvideomenu_title_offs) -- addiu   $v0, $s4, 0xa38 -> addiu $v0, $s4, cvideomenu_title_offs
eeInsnReplace(0x1c6de0, 0x0c0625e6, cvideomenu_call) -- jal CMessage::setText -> jal cvideomenu_code
eeInsnReplace(0x1c6e58, 0x3c0141a0, 0x3c014270) -- li.s $f1, 20.0, li.s $f1, 60.0
eeInsnReplace(0x1c6e94, 0x3c05002d, 0x3c050000 | (cvideomode_addr >> 16)) -- lui $a1, (cvideomode_addr >> 16)
eeInsnReplace(0x1c6e9c, 0x24a51740, 0x24a50000 | (cvideomode_addr & 0xffff)) -- addiu $a1, $a1, (cvideomode_addr & 0xffff)
eeInsnReplace(0x1c6ea0, 0xae800bbc, 0xae800000 | cvideomenu_sel_offs) -- sw $zero, 0xbbc($s4) -> sw $zero, cvideomenu_sel_offs($s4)
eeInsnReplace(0x1c6eac, 0xae830bc0, 0x00000000) -- sw $v1, 0xbc0($s4) -> nop

-- CNetworkMenu::init
eeInsnReplace(0x1c70d8, 0x24110002, 0x24110000 | (videomenu_count - 1)) -- li $s1, 2 -> li $s1, videomenu_count - 1

-- CNetworkMenu::process
eeInsnReplace(0x1c7290, 0x24110002, 0x24110000 | (videomenu_count - 1)) -- li $s1, 2 -> li $s1, videomenu_count - 1
eeInsnReplace(0x1c72e8, 0x24120002, 0x24120000 | (videomenu_count - 1)) -- li $s2, 2 -> li $s2, videomenu_count - 1
eeInsnReplace(0x1c7384, 0x8e250bbc, 0x8e250000 | cvideomenu_sel_offs) -- lw $a1, 0xbbc($s1) -> lw $a1, cvideomenu_sel_offs($s1)
eeInsnReplace(0x1c73ac, 0x2a620003, 0x2a620000 | videomenu_count) -- slti $v0, $s3, 3 -> slti $v0, $s3, videomenu_count
eeInsnReplace(0x1c73b8, 0x8e240bbc, 0x8e240000 | cvideomenu_sel_offs) -- lw $a0, 0xbbc($s1) -> lw $a0, cvideomenu_sel_offs($s1)
-- eeInsnReplace(0x1c7420, 0x8e230bbc, 0x8e230000 | cvideomenu_sel_offs) -- lw $v1, 0xbbc($s1) -> lw $v1, cvideomenu_sel_offs($s1)
eeInsnReplace(0x1c7478, 0x8e220bbc, 0x8e220000 | cvideomenu_sel_offs) -- lw $v0, 0xbbc($s1) -> lw $v0, cvideomenu_sel_offs($s1)
eeInsnReplace(0x1c7480, 0x28430003, 0x28430000 | videomenu_count) -- slti $v1, $v0, 3 -> slti $v1, $v0, videomenu_count
eeInsnReplace(0x1c7488, 0xae220bbc, 0xae220000 | cvideomenu_sel_offs) -- sw $v0, 0xbbc($s1) -> sw $v0, cvideomenu_sel_offs($s1)
eeInsnReplace(0x1c748c, 0xae200bbc, 0xae200000 | cvideomenu_sel_offs) -- sw $zero, 0xbbc($s1) -> sw $zero, cvideomenu_sel_offs($s1)
eeInsnReplace(0x1c74c4, 0x8e220bbc, 0x8e220000 | cvideomenu_sel_offs) -- lw $v0, 0xbbc($s1) -> lw $v0, cvideomenu_sel_offs($s1)
eeInsnReplace(0x1c74d0, 0xae220bbc, 0xae220000 | cvideomenu_sel_offs) -- sw $v0, 0xbbc($s1) -> sw $v0, cvideomenu_sel_offs($s1)
eeInsnReplace(0x1c74d4, 0x24020002, 0x24020000 | (videomenu_count - 1)) -- li $v0, 2 -> li $v0, videomenu_count - 1
eeInsnReplace(0x1c74d8, 0xae220bbc, 0xae220000 | cvideomenu_sel_offs) -- sw $v0, 0xbbc($s1) -> sw $v0, cvideomenu_sel_offs($s1)

-- CMainMenu::process
eeInsnReplace(0x1b56fc, 0x24040ee0, 0x24041200) -- li $a0, 0xee0 -> li $a0, 0x1200

-- COptionsMenu::COptionsMenu
eeInsnReplace(0x1b6328, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4
eeInsnReplace(0x1b63b0, 0x26be0748, 0x26be08e4) -- addiu $fp, $s5, 0x748 -> addiu $fp, $s5, 0x8e4
eeInsnReplace(0x1b63b4, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4
eeInsnReplace(0x1b63dc, 0x26a20d58, 0x26a21078) -- addiu $v0, $s5, 0xd58 -> addiu $v0, $s5, 0x1078
eeInsnReplace(0x1b6438, 0x26a405ac, 0x26a40748) -- addiu $a0, $s5, 0x5ac -> addiu $a0, $s5, 0x748
eeInsnReplace(0x1b6450, 0x26a40bd4, 0x26a40ef4) -- addiu $a0, $s5, 0xbd4 -> addiu $a0, $s5, 0xef4
eeInsnReplace(0x1b645c, 0x24170003, 0x24170004) -- li $s7, 3 -> li $s7, 4
eeInsnReplace(0x1b647c, 0x26a408cc, 0x26a40a68) -- addiu $a0, $s5, 0x8cc -> addiu $a0, $s5, 0xa68
eeInsnReplace(0x1b6490, 0x26a40a50, 0x26a40bec) -- addiu $a0, $s5, 0xa50 -> addiu $a0, $s5, 0xbec
eeInsnReplace(0x1b6494, 0x0c0625e6, coptionsmenu_call) -- jal CMessage::setText -> jal coptionsmenu_code
eeInsnReplace(0x1b6594, 0xaea00edc, 0xaea011fc) --  sw $zero, 0xedc($s5) ->  sw $zero, 0x11fc($s5)

-- COptionsMenu::cacheMessages
eeInsnReplace(0x1cdf5c, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4

-- COptionsMenu::flushMessages
eeInsnReplace(0x1cdfb4, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4

-- COptionsMenu::init
eeInsnReplace(0x1b67c0, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4

-- COptionsMenu::process
eeInsnReplace(0x1b694c, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4
eeInsnReplace(0x1b69a8, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4
eeInsnReplace(0x1b6a44, 0x8e650edc, 0x8e6511fc) -- lw $a1, 0xedc($s3) -> lw $a1, 0x11fc($s3)
eeInsnReplace(0x1b6a6c, 0x2a420004, 0x2a420005) -- slti $v0, $s2, 4 -> slti $v0, $s2, 5
eeInsnReplace(0x1b6a78, 0x8e640edc, 0x8e6411fc) -- lw $a0, 0xedc($s3) -> lw $a0, 0x11fc($s3)
eeInsnReplace(0x1b6ae0, 0x8e630edc, 0x8e6311fc) -- lw $v1, 0xedc($s3) -> lw $v1, 0x11fc($s3)
eeInsnReplace(0x1b6b68, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4
eeInsnReplace(0x1b6c30, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4
eeInsnReplace(0x1b6cf8, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4
eeInsnReplace(0x1b6ed0, 0x24110003, 0x24110004) -- li $s1, 3 -> li $s1, 4
eeInsnReplace(0x1b6fa0, 0x8e620edc, 0x8e6211fc) -- lw $v0, 0xedc($s3) -> lw $v0, 0x11fc($s3)
eeInsnReplace(0x1b6fa8, 0x28430004, 0x28430005) -- slti $v1, $v0, 4 -> slti $v1, $v0, 5
eeInsnReplace(0x1b6fb0, 0xae620edc, 0xae6211fc) -- sw $v0, 0xedc($s3) -> sw $v0, 0x11fc($s3)
eeInsnReplace(0x1b6fb4, 0xae600edc, 0xae6011fc) -- sw $zero, 0xedc($s3) -> sw $zero, 0x11fc($s3)
eeInsnReplace(0x1b6fec, 0x8e620edc, 0x8e6211fc) -- lw $v0, 0xedc($s3) -> lw $v0, 0x11fc($s3)
eeInsnReplace(0x1b6ff8, 0xae620edc, 0xae6211fc) -- sw $v0, 0xedc($s3) -> sw $v0, 0x11fc($s3)
eeInsnReplace(0x1b6ffc, 0x24020003, 0x24020004) -- li $v0, 3 -> li $v0, 4
eeInsnReplace(0x1b7000, 0xae620edc, 0xae6211fc) -- sw $v0, 0xedc($s3) -> sw $v0, 0x11fc($s3)

-- Change Save/Load Options to index 4
eeInsnReplace(0x1b6b0c, 0x24020003, 0x24020004) -- li $v0, 3 -> li $v0,4
	
-- Hook our alloc code
eeInsnReplace(0x1b6be8, 0x0c081e2a, cvideomenu_alloc_call) -- jal __builtin_new -> jal cvideomenu_alloc_code

-- COptionsMenu::render patches
local isVideoMenu = function(ptr)
	return eeObj.ReadMem32(ptr+0xd4) == 0x2c8980 -- CNetworkMenu::vtbl
end

local loadSelHook = function()
	local op = eeObj.ReadMem32(eeObj.GetPC())
	local rt = (op >> 16) & 0x1f
	local fp = eeObj.GetGpr(gpr.fp)
	
	if isVideoMenu(fp) == true then
		eeObj.SetGpr(rt, eeObj.ReadMem32(fp+cvideomenu_sel_offs))
	else
		eeObj.SetGpr(rt, eeObj.ReadMem32(fp+coptionsmenu_sel_offs))
	end
end

local titleHook = function()
	local fp = eeObj.GetGpr(gpr.fp)
	if isVideoMenu(fp) == true then
		eeObj.SetGpr(gpr.a0, fp+cvideomenu_title_offs)
	else
		eeObj.SetGpr(gpr.a0, fp+coptionsmenu_title_offs)
	end
end

local itemsCoordHook = function()
	local fp = eeObj.GetGpr(gpr.fp)
	if isVideoMenu(fp) == true then
		eeObj.SetFpr(0, eeObj.ReadMemFloat(eeObj.GetGpr(gpr.v0) + cvideomenu_items_offs))
	else
		eeObj.SetFpr(0, eeObj.ReadMemFloat(eeObj.GetGpr(gpr.v0) + coptionsmenu_items_offs))
	end
end

local itemsHook = function()
	local fp = eeObj.GetGpr(gpr.fp)
	if isVideoMenu(fp) == true then
		eeObj.SetGpr(gpr.a0, eeObj.GetGpr(gpr.a0) + cvideomenu_items_offs - 0x748)
	else
		eeObj.SetGpr(gpr.a0, eeObj.GetGpr(gpr.a0) + coptionsmenu_items_offs - 0x748)
	end
end

local compareHook = function()
	local fp = eeObj.GetGpr(gpr.fp)
	local count = eeObj.GetGpr(gpr.s4)
	local compare = optionsmenu_count
	
	if isVideoMenu(fp) == true then
		compare = videomenu_count
	end
		
	if count < compare then
		eeObj.SetGpr(gpr.v0, 1)
	else
		eeObj.SetGpr(gpr.v0, 0)
	end
end

local applyPatchesHook = function()
	-- write menu options to memory
	local video_options = "Video Options"
	eeObj.WriteMemStrZ(cvideomode_addr, video_options)
	
	local base = cvideomode_settings_addr
	for y = 1, videomenu_count do
		local option = vidmodes[y]
		eeObj.WriteMemStrZ(base, option)
		base = base + 0x20		
	end
	
	-- patch CNetworkMenu::vtbl
	eeObj.WriteMem32(0x2c89ac, 0x001b70f0) -- CNetworkMenu::render -> COptionsMenu::render
end

local processHook = function()
	local sel = eeObj.GetGpr(gpr.v1)
	if sel == 3 then
		eeObj.SetGpr(gpr.v0, 3)
	end
end

local setModeHook = function()
	local ptr = eeObj.GetGpr(gpr.s1)
	local mode = eeObj.ReadMem32(ptr+cvideomenu_sel_offs)

--	print(string.format("mode: %s curvideomode %s", mode, curvideomode))
	
	if mode ~= curvideomode then
		switchVideoMode(mode)
		curvideomode = mode
	end
	
	eeObj.SetGpr(gpr.v1, 0)
end

local restoreModeHook = function()
	local ptr = eeObj.GetGpr(gpr.s4)
	eeObj.WriteMem32(ptr+cvideomenu_sel_offs, curvideomode)
end

local isEmuHook = function(opcode, pc)
	local detect = eeObj.ReadMem32(0x100198)
	
	if detect == 0x3c040032 then
		local patches = {
			[0x1b4820] = 0x27bdffb0,
			[0x1b6ae4] = 0x24020001,
			[0x1b74e0] = 0x8fc60edc,
			[0x1b7550] = 0x8fc20edc,
			[0x1b75a8] = 0x8fc50edc,
			[0x1b747c] = 0x27c40d58,
			[0x1b750c] = 0xc4400748,
			[0x1b7588] = 0x03c42021,
			[0x1b75d0] = 0x2a820004,
			[0x1c7420] = 0x8e230bbc,
			[0x1c6ea4] = 0x2403ffff,
			
			[0x1adee8] = 0x27a30120,
			[0x1ae1f8] = 0x24050001,
			[0x1ad42c] = 0x00002010,
			[0x1ad488] = 0x3c020025,
			[0x1d6eb8] = 0x27bdf760,
			[0x1d7094] = 0xc7b40888,
			[0x1aedc8] = 0x27bdffc0,
			
			[0x216698] = 0x27bdffe0,

			[0x1AC8E8] = 0x0C07C360,
			[0x1ADD58] = 0x3C04002D,
			[0x1ACCFC] = 0x0C075BAE
		}
		
		assert(patches[pc] ~= nil, string.format("Overlay opcode mismatch @ 0x%06x", pc))
		assert(patches[pc] == opcode, string.format("Overlay opcode mismatch @ 0x%06x", pc))

		return true
	end
	
	return false
end

local isMS6Hook = function(opcode, pc)
	local detect = eeObj.ReadMem32(0x100198)
	
	if detect == 0x3c040050 then
		local patches = {
			[0x17cbbc] = 0x27bdff90,
			[0x17cb68] = 0xdfb10008,
			[0x1086ec] = 0x27bdf780,
			[0x1088b4] = 0xdfbf0878,
			[0x1059d0] = 0x27bdfbc0,

			[0x16a028] = 0x27bdffe0,

			[0x15F12C] = 0xAE200004
		}
		
		assert(patches[pc] ~= nil, string.format("Overlay opcode mismatch @ 0x%06x", pc))
		assert(patches[pc] == opcode, string.format("Overlay opcode mismatch @ 0x%06x", pc))
		
		return true
	end
	
	return false
end


-- Menu Hooks
eeObj.AddHook(0x1b4820, isEmuHook, applyPatchesHook) -- CMainMenu::CMainMenu
eeObj.AddHook(0x1b6ae4, isEmuHook, processHook) -- COptionsMenu::process
eeObj.AddHook(0x1b74e0, isEmuHook, loadSelHook) -- COptionsMenu::render
eeObj.AddHook(0x1b7550, isEmuHook, loadSelHook) -- COptionsMenu::render
eeObj.AddHook(0x1b75a8, isEmuHook, loadSelHook) -- COptionsMenu::render
eeObj.AddHook(0x1b747c, isEmuHook, titleHook) -- COptionsMenu::render
eeObj.AddHook(0x1b750c, isEmuHook, itemsCoordHook) -- COptionsMenu::render
eeObj.AddHook(0x1b7588, isEmuHook, itemsHook) -- COptionsMenu::render
eeObj.AddHook(0x1b75d0, isEmuHook, compareHook) -- COptionsMenu::render
eeObj.AddHook(0x1c7420, isEmuHook, setModeHook) -- CNetworkMenu::process
eeObj.AddHook(0x1c6ea4, isEmuHook, restoreModeHook) -- CNetworkMenu::CNetworkMenu

-- Emu Hooks
eeObj.AddHook(0x1adee8, isEmuHook, L1) -- mainProgram
eeObj.AddHook(0x1ae1f8, isEmuHook, L2) -- mainProgram
eeObj.AddHook(0x1ad42c, isEmuHook, L1) -- runGame
eeObj.AddHook(0x1ad488, isEmuHook, L2) -- runGame
eeObj.AddHook(0x1d6eb8, isEmuHook, L1) -- ps2InitialLoad
eeObj.AddHook(0x1d7094, isEmuHook, L2) -- ps2InitialLoad
eeObj.AddHook(0x1aedc8, isEmuHook, L1) -- LaunchMS6

-- MS6 Hooks
eeObj.AddHook(0x17cbbc, isMS6Hook, L1) -- mainMS6
eeObj.AddHook(0x17cb68, isMS6Hook, L2) -- InitMain
eeObj.AddHook(0x1086ec, isMS6Hook, L1) -- ps2InitialLoad
eeObj.AddHook(0x1088b4, isMS6Hook, L2) -- ps2InitialLoad
eeObj.AddHook(0x1059d0, isMS6Hook, L1) -- mainMS6


----------------------------------------------------------------------
-- Sound Volume scaling

local applyVolumeScalingHook = function()
	eeObj.SetFpr(12, eeObj.GetFpr(12) * volumeScale)
end

eeObj.AddHook(0x216698, isEmuHook, applyVolumeScalingHook) -- CSound::setTweakChannelVol
eeObj.AddHook(0x16a028, isMS6Hook, applyVolumeScalingHook) -- CSound::setTweakChannelVol

local movieValue = math.floor(movieScale * 0x7fff)
eeInsnReplace(0x195ecc, 0x24077fff, 0x24070000 | movieValue) -- CMPEGViewer::processAudio
eeInsnReplace(0x195ee0, 0x24077fff, 0x24070000 | movieValue) -- CMPEGViewer::processAudio


-- Fight stick

local pad = function()
	switchVideoMode(SaveData.videomode)
	emuObj.AddVsyncHook(update_notifications_p1)
	emuObj.AddVsyncHook(update_notifications_p2)
end

emuObj.AddPadHook(onHIDPadEvent)
emuObj.AddEntryPointHook(pad)

-- Remove Playmore logo

local bye_playmore = function()
	local strptr = eeObj.GetGpr(gpr.v0)
	local filename = eeObj.ReadMemStr(strptr)
	if filename == "a_preecine_snk_playmorelogo.tex" then
		eeObj.WriteMem32(0x105A50, 0x10000041) -- CMini3D::cacheEmbeddedTextureUngracefully(textureStruct *) -> b 0x00105B58
	end
end

eeObj.AddHook(0x15F12C, isMS6Hook, bye_playmore)

-- replace SNK logo

local snklogo_on = function()
	snklogo = 1
	switchVideoMode(SaveData.videomode)
end

local timer = function()
	if snklogo == 1 then
		vsync_timer=vsync_timer+1
		if (vsync_timer==350) then
			snklogo = 0
			switchVideoMode(SaveData.videomode)
			vsync_timer = 0
		end
	end
end

eeObj.AddHook(0x1ADD58, isEmuHook, snklogo_on)
emuObj.AddVsyncHook(timer)
