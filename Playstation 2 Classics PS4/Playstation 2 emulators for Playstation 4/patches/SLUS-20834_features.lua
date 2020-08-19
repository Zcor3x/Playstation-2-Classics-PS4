-- Lua 5.3
-- Title:   The King of Fighters 2000 PS2 - SLUS-20834 (USA)
-- Author:  Ernesto Corvi

-- Changelog:
-- v1.2: Added Video Options menu
-- v1.3: Delayed turning on scanlines until after Playmore logo. TGL
-- v1.4: Changed SNK logo at boot. TGL
-- v1.5: Added PS3 fight stick support. TGL
-- v1.6: Fixed bug 9676
-- v2.0: Fixed P2 couldn't access Exit in Options Menu

apiRequest(1.2) -- request version 1.2 API. Calling apiRequest() is mandatory.

local eeObj  		= getEEObject()
local emuObj		= getEmuObject()

local gpr = require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])
local kFilterMode, kWrapMode, kBlendMultiplier, kBlendFunc = require("sprite")
local PadConnectType = require("pad-connect-type")

local SaveData = emuObj.LoadConfig(0)

if not next(SaveData) then
	SaveData.videomode = 0
end

local vsync_timer=0
local frames = 0

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

-- ------------------------------------------------------------
local STATE_STOPPED		= 0
local STATE_RUNNING		= 1

local notify_ypos = 72
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


-- ------------------------------------------------------------

-- ---------------------------------------------------
-- the global function 'Global_InitGpuResources()' is invoked by the emulator after
-- the GS has been initialized.  Textures and Shaders must be loaded here.
--
Global_InitGpuResources = function()
	-- # Fragment Shader 0 is fixed as the default no-thrills as-is renderer.
	emuObj.LoadFsShader(1, "./shader_SL480i_p.sb")		-- (1) = 480P ScanLine Sim
	texture1.Load("./SNK_BEZEL_3.png")
	texture2.Load("./SNK_BEZEL_2.png")
	texture3.Load("./SNK_LOGO.png")
	texture4.Load("./p1.png")
	texture5.Load("./p2.png")
	texture6.Load("./p1d.png")
	texture7.Load("./p2d.png")

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

	local keyframe = 15

	notify_frames_p1 = notify_frames_p1 + 1

	if math.ceil(notify_frames_p1/keyframe) == notify_frames_p1/keyframe then blink_on_p1 = not blink_on_p1 end
	if blink_on_p1 == true then notify_ypos = 72 end
	if blink_on_p1 == false then notify_ypos = -72 end

--	print(string.format("rounded %s, floating %s, blink %s ypos %s", math.ceil(notify_frames_p1/keyframe), notify_frames_p1/keyframe, blink_on_p1, notify_ypos))

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

	local keyframe = 15

	notify_frames_p2 = notify_frames_p2 + 1

	if math.ceil(notify_frames_p2/keyframe) == notify_frames_p2/keyframe then blink_on_p2 = not blink_on_p2 end
	if blink_on_p2 == true then notify_ypos = 72 + notify_ysize + 8 end
	if blink_on_p2 == false then notify_ypos = -72 - notify_ysize - 8 end

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
	if pad_type == PadConnectType.HID then
--	print(string.format("slot %s, connected %s, pad_type %s", slot, connected, pad_type))
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

-- ---------------------------------------------------

local scanlineParams = {
	240.0,		-- float scanlineCount
   	0.7,		-- float scanlineHeight;
	1.5,        -- float scanlineBrightScale;
	0.5,        -- float scanlineAlpha;
	0.5         -- float vignetteStrength;
}

-- ---------------------------------------------------
-- Full Screen (480p) NoFX
-- ---------------------------------------------------

local original = function()
	sprite0.BindTexture(0)
	sprite0.BindFragmentShader(0)
	sprite0.SetPosXY((1920-1440)/2,0)
	sprite0.SetSizeXY(1440,1080)
	sprite0.Enable()
	sprite1.Disable()
end

-- ---------------------------------------------------
-- Full Screen + ScanLines (480i)
-- ---------------------------------------------------

local scanlines = function()
	sprite0.BindTexture(0)
	sprite0.SetPosXY((1920-1440)/2,0)
	sprite0.SetSizeXY(1440,1080)
	sprite0.BindFragmentShader(1)
	sprite0.SetShaderParams(scanlineParams)
	sprite0.Enable()
	sprite1.Disable()
end

-- ---------------------------------------------------
-- SNK Overlay1 + ScanLines (480i)
-- ---------------------------------------------------

local bezel_scanlines1 = function()
	sprite0.BindTexture(0)
	sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
	sprite0.SetSizeXY(1280,896)
	sprite0.BindFragmentShader(1)
	sprite0.SetShaderParams(scanlineParams)
	sprite0.Enable()

	sprite1.BindTexture(1)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end

-- ---------------------------------------------------
-- SNK Overlay2 + ScanLines (480i)
-- ---------------------------------------------------

local bezel_scanlines2 = function()
	sprite0.BindTexture(0)
	sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
	sprite0.SetSizeXY(1280,896)
	sprite0.BindFragmentShader(1)
	sprite0.SetShaderParams(scanlineParams)
	sprite0.Enable()

	sprite1.BindTexture(2)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end
-- ---------------------------------------------------
-- SNK Overlay1 NoFX
-- ---------------------------------------------------
local bezel1 = function()
	sprite0.BindTexture(0)
	sprite0.BindFragmentShader(0)
	sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
	sprite0.SetSizeXY(1280,896)
	sprite0.Enable()

	sprite1.BindTexture(1)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end
-- ---------------------------------------------------
-- SNK Overlay2 NoFX
-- ---------------------------------------------------
local bezel2 = function()
	sprite0.BindTexture(0)
	sprite0.BindFragmentShader(0)
	sprite0.SetPosXY((1920-1280)/2, (1080-896)/2)
	sprite0.SetSizeXY(1280,896)
	sprite0.Enable()

	sprite1.BindTexture(2)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end
-- ---------------------------------------------------
-- SNK Logo
-- ---------------------------------------------------
local slogo = function()
	sprite1.BindTexture(3)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end
-- ---------------------------------------------------
-- Video Mode Hooks
--
-- The following patches embed a Video setting in the Options menu of the game
-- 

-- List video modes here. Make sure to include extra spaces to pad the string (max string size = 15)
local vidmodes = { "ORIGINAL       ",
                   "SCANLINES      ",
                   "ART1           ",
                   "ART1+SCANLINES ",
                   "ART2           ",
                   "ART2+SCANLINES "}

-- The following function will get called when a video mode switch is requested.
-- Parameter is the video mode index where the first index = 0
local function switchVideoMode(index)

	-- switch video mode here based on the index
	print(string.format("video mode: %d", index))

	if index == 0 then
		original()
	elseif index == 1 then
		scanlines()
	elseif index == 2 then
		bezel1()
	elseif index == 3 then
		bezel_scanlines1()
	elseif index == 4 then
		bezel2()
	elseif index == 5 then
		bezel_scanlines2()
	end

	if index ~= SaveData.videomode then
		SaveData.videomode = index
		emuObj.SaveConfig(0, SaveData)
	end
	
end



-- ---------------------------------------------------

-- ---------------------------------------------------

local menu_options = {
	["menu"] = { "DIFFICULTY", "CONTROLLER CONFIG.", "BATTLE CONFIG.", "FLASH", "VIBRATION", "SOUND", "MUSIC", "VIDEO", "SAVE LOAD", "CHART", "EXIT" },
	["menupos"] = { ["x"] = 3, ["y"] = 3 },
	["itempos"] = { ["x"] = 22, ["y"] = 3 }
}

local function encodeCoords(coords)
	local x = coords.x
	local y = coords.y
	
	y = y & 0x1f
	y = y | ((x & 0x07) << 5)
	y = y + 2

	x = 0x70 | (x >> 3)
	
	return { ["x"] = x, ["y"] = y}
end

-- relevant addresses
local base_address = 0xf7000
local base_menu = base_address
local base_seltable = base_address + 0x100
local base_seloptions = base_address + 0x180
local base_vidtable = base_address + 0x300
local base_vidoptions = base_address + 0x380
local base_vidmode = base_address + 0x500

local function gen_menu()
	local base = base_menu
	local coords = encodeCoords(menu_options["menupos"])
	local menu = menu_options["menu"]
	
	for x = 1, #menu do
		eeObj.WriteMem8(base, coords.y)
		eeObj.WriteMem8(base+1, coords.x)
		eeObj.WriteMem8(base+2, 0xA9)
		eeObj.WriteMemStr(base+3, menu[x])
		eeObj.WriteMem8(base+3+#(menu[x]), 0xFE)
		base = base + 4 + #(menu[x])
		coords.y = coords.y + 2
	end
	
	eeObj.WriteMem8(base-1, 0xFF)
end

local function gen_seloptions()
	local base = base_seltable
	local menu = menu_options["menu"]
	local coords = encodeCoords(menu_options["menupos"])
	
	for x = 1, #menu do
		local addr = base_seloptions + (0x20 * (x-1))
		eeObj.WriteMem32(base, addr) -- pointer to item
		
		eeObj.WriteMem8(addr, coords.y)
		eeObj.WriteMem8(addr+1, coords.x)
		eeObj.WriteMem8(addr+2, 0xE9)
		eeObj.WriteMemStr(addr+3, menu[x])
		eeObj.WriteMem8(addr+3+#(menu[x]), 0xFF)
		base = base + 4
		coords.y = coords.y + 2
	end
end

local function gen_vidmodes_table()
	local base = base_vidoptions
	local pos = { ["x"] = menu_options["itempos"].x, ["y"] = menu_options["itempos"].y + 14 }
	local coords = encodeCoords(pos)
	
	for x = 1, #vidmodes do
		eeObj.WriteMem8(base+0, coords.y)
		eeObj.WriteMem8(base+1, coords.x)
		eeObj.WriteMem8(base+2, 0xB9)
		eeObj.WriteMemStr(base+3, vidmodes[x])
		eeObj.WriteMem8(base+3+#(vidmodes[x]), 0xFF)
		base = base + 0x20
	end

	base = base_vidoptions
	for x = 0, #vidmodes - 1 do
		eeObj.WriteMem32(base_vidtable+(x*4), base)
		base = base + 0x20
	end
end

local function fixup_menuitems()
	local pos = { ["x"] = menu_options["itempos"].x, ["y"] = menu_options["itempos"].y }
	local coords = encodeCoords(pos)
	
	-- Level select
	local LEVELSEL_TBL0 = 0x547770
	local LEVELSEL_TBL1 = 0x547790
	
	for x = 0, 7 do
		local addr = eeObj.ReadMem32(LEVELSEL_TBL0 + (x*4))
		eeObj.WriteMem8(addr, coords.y)
		eeObj.WriteMem8(addr+1, coords.x)
	end
	
	pos.x = pos.x + 2
	coords = encodeCoords(pos)
	
	for x = 0, 7 do
		local addr = eeObj.ReadMem32(LEVELSEL_TBL1 + (x*4))
		eeObj.WriteMem8(addr, coords.y)
		eeObj.WriteMem8(addr+1, coords.x)
	end
	
	local FLG_TBL0 = 0x5c30f8
	
	pos.x = pos.x - 2
	pos.y = pos.y + 6 
	coords = encodeCoords(pos)

	for x = 0, 1 do
		local addr = eeObj.ReadMem32(FLG_TBL0 + (x*4))
		eeObj.WriteMem8(addr, coords.y)
		eeObj.WriteMem8(addr+1, coords.x)
	end
		
	local VIB_TBL0 = 0x5c3100
	
	pos.y = pos.y + 2
	coords = encodeCoords(pos)
	
	for x = 0, 1 do
		local addr = eeObj.ReadMem32(VIB_TBL0 + (x*4))
		eeObj.WriteMem8(addr, coords.y)
		eeObj.WriteMem8(addr+1, coords.x)
	end
	
	local SOUND_TBL0 = 0x5c3108
	
	pos.y = pos.y + 2
	coords = encodeCoords(pos)
	
	for x = 0, 1 do
		local addr = eeObj.ReadMem32(SOUND_TBL0 + (x*4))
		eeObj.WriteMem8(addr, coords.y)
		eeObj.WriteMem8(addr+1, coords.x)
	end
		
	local MUSIC_TBL0 = 0x5c3110
	
	pos.y = pos.y + 2
	coords = encodeCoords(pos)
	
	for x = 0, 1 do
		local addr = eeObj.ReadMem32(MUSIC_TBL0 + (x*4))
		eeObj.WriteMem8(addr, coords.y)
		eeObj.WriteMem8(addr+1, coords.x)
	end
	
end
	
local function apply_patches()
	gen_menu()
	gen_seloptions()
	gen_vidmodes_table()
	fixup_menuitems()
end
	
local function prev_vid_mode()
	local current = eeObj.ReadMem32(base_vidmode)
	
	if current == 0 then
		current = #vidmodes - 1
	else
		current = current - 1
	end
	
	switchVideoMode(current)
	eeObj.WriteMem32(base_vidmode, current)
end

local function next_vid_mode()
	local current = eeObj.ReadMem32(base_vidmode)
		
	if current == #vidmodes - 1 then
		current = 0
	else
		current = current + 1
	end
	
	switchVideoMode(current)
	eeObj.WriteMem32(base_vidmode, current)
end

eeObj.AddHook(0x243d00, 0x27bdfff0, function()
	apply_patches()
end)
	
eeObj.AddHook(0x243c4c, 0x24427150, function()
	eeObj.SetGpr(gpr.v0, base_menu) -- OPTMODE_MES
end)

eeObj.AddHook(0x243744, 0x24427740, function()
	eeObj.SetGpr(gpr.v0, base_seltable) -- OPTMODE_TBL
end)

eeObj.AddHook(0x240d0c, 0x24020003, function()
	local sel = eeObj.GetGpr(gpr.s3)
	
	if sel == 1 then
		eeObj.SetGpr(gpr.v0, 7)
	end
end)

local vid_table_hook = function()
	local sel = eeObj.GetGpr(gpr.s3)
	
	if sel == 1 then
		eeObj.SetGpr(gpr.v0, base_vidtable)
	end
end

local left_key_hook = function()
	local sel = eeObj.GetGpr(gpr.s3)
	
	if sel == 1 then
		prev_vid_mode()
	end
end

local right_key_hook = function()
	local sel = eeObj.GetGpr(gpr.s3)
	
	if sel == 1 then
		next_vid_mode()
	end
end

eeObj.AddHook(0x240d1c, 0x27828588, vid_table_hook)
eeObj.AddHook(0x240e04, 0x27828588, vid_table_hook)
eeObj.AddHook(0x241408, 0x27828588, right_key_hook) -- right
eeObj.AddHook(0x2414ec, 0x27828588, left_key_hook) -- left

-- change number of menu items from 9 to 10
eeInsnReplace(0x243ca0, 0x24020009, 0x2402000a) -- li $v0, 9 -> li $v0, 10
eeInsnReplace(0x243b08, 0x24020009, 0x2402000a) -- li $v0, 9 -> li $v0, 10

-- replace menu checks 7->8, 8->9, 9->10
eeInsnReplace(0x2424a8, 0x24030009, 0x2403000a) -- li $v1, 9 -> li $v1, 10
eeInsnReplace(0x2424b8, 0x24030008, 0x24030009) -- li $v1, 8 -> li $v1, 9
eeInsnReplace(0x2424c4, 0x24030007, 0x24030008) -- li $v1, 7 -> li $v1, 8

-- overlay to display video modes. We reuse the FLASH_CHECK call
local overlay = InsnOverlay({
	0x27bdffb0, -- addiu $sp, -0x50
	0xffbf0000, -- sd $ra, 0x00($sp)
	0xffb00010, -- sd $s0, 0x10($sp)
	0xffb10020, -- sd $s1, 0x20($sp)
	0xffb20030, -- sd $s2, 0x30($sp)
	0xffb30040, -- sd $s3, 0x40($sp)
	
	-- save D0, D1, D2 in $s0, $s1, $s2
	
	0x3c010067, -- lui $at, 0x67
	0x8c30d070, -- lw $s0, m68kD0
	0x8c31d074, -- lw $s1, m68kD1
	0x8c32d078, -- lw $s2, m68kD2
	
	0x3c010000 | (base_vidmode >> 16),    -- lui $at, base_vidmode >> 16
	0x8c220000 | (base_vidmode & 0xffff), -- lw $v0, base_vidmode ; video mode => D2
	0x3c010067, -- lui $at, 0x67
	0xac22d078, -- sw $v0, m68kD2
	0x0c090340, -- jal FLASH_CHECK
	0x24130001, -- li $s3, 1
	
	0x3c010067, -- lui $at, 0x67
	0xac30d070, -- sw $s0, m68kD0
	0xac31d074, -- sw $s1, m68kD1
	0xac32d078, -- sw $s2, m68kD2
	0x0c090340, -- jal FLASH_CHECK
	0x24130000, -- li $s3, 0
	
	0xdfb30040, -- ld $s3, 0x40($sp)
	0xdfb20030, -- ld $s2, 0x30($sp)
	0xdfb10020, -- ld $s1, 0x20($sp)
	0xdfb00010, -- ld $s0, 0x10($sp)
	0xdfbf0000, -- ld $ra, 0x00($sp)
	0x03e00008, -- jr $ra
	0x27bd0050  -- addiu $sp, 0x50
})
local call_overlay = 0x0c000000 | (overlay >> 2)
eeInsnReplace(0x243870, 0x0c090340, call_overlay)

local restoreVideoModeHook = function()
	eeObj.WriteMem32(base_vidmode, SaveData.videomode)
	switchVideoMode(SaveData.videomode)
	emuObj.AddVsyncHook(update_notifications_p1)
	emuObj.AddVsyncHook(update_notifications_p2)
end

local snklogo = function()
	vsync_timer=vsync_timer+1
	if (vsync_timer==850) then
		slogo()
		emuObj.RemoveVsyncHook(frames)
	end
end

frames = emuObj.AddVsyncHook(snklogo)
local after_new_snk = eeObj.AddHook(0x14a060,0x24030002,restoreVideoModeHook)
local pad = emuObj.AddPadHook(onHIDPadEvent)
