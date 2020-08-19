-- Lua 5.3
-- Title: Samurai Shodown Anthology - SLUS-21629 (USA) v1.01
-- Author: Nicola Salmoria
-- Date: October 12, 2016


local gpr = require( "ee-gpr-alias" )

apiRequest(1.6)

local eeObj		= getEEObject()
local emuObj	= getEmuObject()

local kFilterMode, kWrapMode, kBlendMultiplier, kBlendFunc = require("sprite")
local PadConnectType = require("pad-connect-type")


local BRIGHT_ADDRESS = 0x7803fc
local BRIGHT_DESCRIPTION_ADDRESS = 0x4d8380
local SETTINGS_ADDRESS = 0x756900

-- a free memory location for our perusal
local DISPLAYMODE_STRING_ADDRESS = 0xf7000

local sprite0 = getSpriteObject(0)
local sprite1 = getSpriteObject(1)

-- Notifications should be assigned to two unused sprite slots.  Since we want them to
-- be displayed on top of everything else, they should be the highest sprites in the list.
local spr_p1_notify = getSpriteObject(2)
local spr_p2_notify = getSpriteObject(3)
local spr_p1d_notify = getSpriteObject(4)
local spr_p2d_notify = getSpriteObject(5)

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
	emuObj.LoadFsShader(1, "./shader_SL480_p.sb")		-- (1) = 480P ScanLine Sim

	texture1.Load("./ART1.png")
	texture2.Load("./ART2.png")
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

	emuObj.ThrottleNorm()

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

	emuObj.ThrottleNorm()

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
	sprite0.BindTexture(0)
	sprite0.BindFragmentShader(0)
	sprite0.SetPosXY((1920-1440)/2,0)
	sprite0.SetSizeXY(1440,1080)
	sprite0.Enable()

	sprite1.Disable()
end

-- ---------------------------------------------------
-- Full Screen + ScanLines (480p)
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
-- SNK Overlay NoFX
-- ---------------------------------------------------
local bezel = function()
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
-- SNK Overlay + ScanLines (480p)
-- ---------------------------------------------------

local bezel_scanlines = function()
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
-- Arcade Overlay NoFX
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
-- Arcade Overlay + ScanLines (480p)
-- ---------------------------------------------------

local bezel2_scanlines = function()
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


local logoON = function()
	emuObj.ThrottleMax()

	sprite0.BindTexture(3)
	sprite0.SetPosXY(0,0)
	sprite0.SetSizeXY(1920,1080)
	sprite0.SetPosUV(0,0)
	sprite0.SetSizeUV(1920,1080)
	sprite0.Enable()

	sprite1.Disable()
end


local VIDEOMODE_ORIGINAL		= 256
local VIDEOMODE_SCANLINES		= 251
local VIDEOMODE_ART1			= 252
local VIDEOMODE_ART1_SCANLINES	= 253
local VIDEOMODE_ART2			= 254
local VIDEOMODE_ART2_SCANLINES	= 255

local videoModes = {
	[VIDEOMODE_ORIGINAL			] = "ORIGINAL",
	[VIDEOMODE_SCANLINES		] = "SCANLINES",
	[VIDEOMODE_ART1				] = "ART1",
	[VIDEOMODE_ART1_SCANLINES	] = "ART1 + SCANLINES",
	[VIDEOMODE_ART2				] = "ART2",
	[VIDEOMODE_ART2_SCANLINES	] = "ART2 + SCANLINES",
}

local lastVideoMode = nil

local function switchVideoMode(mode)
	if lastVideoMode ~= mode then
		lastVideoMode = mode

		emuObj.ThrottleNorm()
	
		if mode == VIDEOMODE_ORIGINAL then
			original()
		elseif mode == VIDEOMODE_SCANLINES then
			scanlines()
		elseif mode == VIDEOMODE_ART1 then
			bezel()
		elseif mode == VIDEOMODE_ART1_SCANLINES then
			bezel_scanlines()
		elseif mode == VIDEOMODE_ART2 then
			bezel2()
		elseif mode == VIDEOMODE_ART2_SCANLINES then
			bezel2_scanlines()
		end
	end
end



local FH1 =	-- printf
	function()
		eeObj.SetGpr(gpr.ra, 0x11afd0)	-- <LoadExecPS2>:
		eeObj.SetGpr(gpr.a0, 0x348710)	-- "cdrom0:\S6\NO1_E.ELF;1"
		eeObj.SetGpr(gpr.a1, 0)
		eeObj.SetGpr(gpr.a2, 0)

		-- also turn on the SNK logo (it will be implicitly tuned off after video mode settings are applied)
		logoON()
	end

local FH2A =	-- increment main menu option
	function()
		local v1 = eeObj.GetGpr(gpr.v1)
		if v1 == 7 then
			eeObj.SetGpr(gpr.v1, 8)	-- skip "exit to main menu"
		end
	end

local FH2B =	-- decrement main menu option
	function()
		local v1 = eeObj.GetGpr(gpr.v1)
		if v1 == 7 then
			eeObj.SetGpr(gpr.v1, 6)	-- skip "exit to main menu"
		end
	end

local FH2C =	-- get pointer of "exit to main menu" string
	function()
		local strPtr = eeObj.GetFprHex(0)
		eeObj.WriteMem8(strPtr, 0)	-- erase the string
	end


local FH3 =
	function()
		local msgId = eeObj.GetGpr(gpr.a0)
		if msgId == 5 then
			eeObj.SetGpr(gpr.v1, 9)	-- skip message
		end
	end


local FH4A =	-- increment the BRIGHT value
	function()
		local bright = eeObj.ReadMem32(BRIGHT_ADDRESS)

		local next = bright + 1
		if next > 256 then
			next = 251
		end

		eeObj.SetGpr(gpr.a0, next)
	end

local FH4B =	-- decrement the BRIGHT value
	function()
		local bright = eeObj.ReadMem32(BRIGHT_ADDRESS)

		local next = bright - 1
		if next < 251 then
			next = 256
		end

		eeObj.SetGpr(gpr.a0, next)
	end


local function forceBright(register)
	local bright = eeObj.GetGpr(register)

	-- update the video mode
	switchVideoMode(bright)

	-- force brightness to 100%
	eeObj.SetGpr(register, 256)
end

local FH5A =	-- read BRIGHT setting
	function()
		forceBright(gpr.a2)
	end
local FH5B =	-- read BRIGHT setting
	function()
		forceBright(gpr.a0)
	end
local FH5C =	-- read BRIGHT setting
	function()
		forceBright(gpr.v1)
	end
local FH5D =	-- read BRIGHT setting
	function()
		forceBright(gpr.t4)
	end


local FH6 =	-- get label for game option
	function()
		local v1 = eeObj.GetGpr(gpr.v1)

		if v1 == 8 then
			eeObj.WriteMemStrZ(DISPLAYMODE_STRING_ADDRESS, "DISPLAY")
			eeObj.SetGpr(gpr.v0, DISPLAYMODE_STRING_ADDRESS)

			eeObj.WriteMemStrZ(BRIGHT_DESCRIPTION_ADDRESS, "The display mode can be changed")
		end
	end


local FH7 =	-- get description for BRIGHT option
	function()
		local bright = eeObj.ReadMem32(BRIGHT_ADDRESS)
		local sp = eeObj.GetGpr(gpr.sp)
		eeObj.WriteMemStrZ(sp + 128, videoModes[bright])
	end


local FH8 =	-- initialize settings
	function()
		eeObj.WriteMem32(SETTINGS_ADDRESS + 0xafe8, 1)	-- auto save enabled
	end


-- register hooks

local CHKDATA_MAIN = 0x3c04001d
local CHKDATA_SS6  = 0x3c040056

local elfChkMain = function(opcode, pc, expectedOpcode)
	local chkData = eeObj.ReadMem32(0x100198)

	if chkData == CHKDATA_MAIN then
		assert(opcode == expectedOpcode, string.format("Overlay opcode mismatch @ 0x%06x: expected 0x%08x, found %08x", pc, expectedOpcode, opcode))
		return true
	else
		return false
	end
end

local elfChkSS6 = function(opcode, pc, expectedOpcode)
	local chkData = eeObj.ReadMem32(0x100198)

	if chkData == CHKDATA_SS6 then
		assert(opcode == expectedOpcode, string.format("Overlay opcode mismatch @ 0x%06x: expected 0x%08x, found %08x", pc, expectedOpcode, opcode))
		return true
	else
		return false
	end
end

local hooks = {
	-- load Samurai Shodown VI on startup
	eeObj.AddHook(0x100850, function(op, pc) return elfChkMain(op, pc, 0xdfbf0030) end, FH1),

	-- skip "exit to main menu" menu option
	eeObj.AddHook(0x24bd84, function(op, pc) return elfChkSS6(op, pc, 0x00001810) end, FH2A),
	eeObj.AddHook(0x24bf90, function(op, pc) return elfChkSS6(op, pc, 0x00001810) end, FH2B),
	-- hide "exit to main menu" menu option
	eeObj.AddHook(0x1cae4c, function(op, pc) return elfChkSS6(op, pc, 0xe7a00080) end, FH2C),

	-- skip "There is no SAMURAI SHODOWN -ANTHOLOGY- data on the memory card" message
	eeObj.AddHook(0x2a4d3c, function(op, pc) return elfChkSS6(op, pc, 0x24030007) end, FH3),

	-- increment/decrement BRIGHT setting: replace with clamp to range 251-256
	eeObj.AddHook(0x27ba2c, function(op, pc) return elfChkSS6(op, pc, 0x00642021) end, FH4A),
	eeObj.AddHook(0x27bc34, function(op, pc) return elfChkSS6(op, pc, 0x00642021) end, FH4B),

	-- force screen brightness to max
	eeObj.AddHook(0x2aa740, function(op, pc) return elfChkSS6(op, pc, 0x8c6603fc) end, FH5A),
	eeObj.AddHook(0x2aaab8, function(op, pc) return elfChkSS6(op, pc, 0x8c6403fc) end, FH5B),
	eeObj.AddHook(0x2ad2f0, function(op, pc) return elfChkSS6(op, pc, 0x8c4303fc) end, FH5C),
	eeObj.AddHook(0x2ad950, function(op, pc) return elfChkSS6(op, pc, 0x8c4303fc) end, FH5C),
	eeObj.AddHook(0x2addb4, function(op, pc) return elfChkSS6(op, pc, 0x8c4303fc) end, FH5C),
	eeObj.AddHook(0x2ae2c8, function(op, pc) return elfChkSS6(op, pc, 0x8c6c03fc) end, FH5D),
	eeObj.AddHook(0x2ae4e4, function(op, pc) return elfChkSS6(op, pc, 0x8c6c03fc) end, FH5D),

	-- patch BRIGHT label
	eeObj.AddHook(0x1c8dec, function(op, pc) return elfChkSS6(op, pc, 0x2463ffff) end, FH6),
	eeObj.AddHook(0x1c9dc4, function(op, pc) return elfChkSS6(op, pc, 0x2463ffff) end, FH6),

	-- patch BRIGHT description
	eeObj.AddHook(0x1c958c, function(op, pc) return elfChkSS6(op, pc, 0x24020006) end, FH7),

	-- enable AUTO SAVE on first boot
	eeObj.AddHook(0x2a5ebc, function(op, pc) return elfChkSS6(op, pc, 0x3c040076) end, FH8),
}


-- Fight stick

HIDPad_Enable()

local addedHooks = false
local pad = function()
	if addedHooks == false then
		addedHooks = true
		emuObj.AddVsyncHook(update_notifications_p1)
		emuObj.AddVsyncHook(update_notifications_p2)

		-- bug report:
		-- Sound volume: The sound is extremely louder than previous titles.
		-- <PS4 recommendation>      -24LKFS(±2)
		-- <The current game sound> -11.59LUFS
		--
		-- So set main volume to 0.25 i.e. about 12dB attenuation.
		emuObj.SetVolumes(0.25, 1.0, 1.0)
	end
end
	
emuObj.AddPadHook(onHIDPadEvent)
emuObj.AddEntryPointHook(pad)




-- Credits

-- Trophy design and development by SCEA ISD SpecOps
-- David Thach Senior Director
-- George Weising Executive Producer
-- Tim Lindquist Senior Technical PM
-- Clay Cowgill Engineering
-- Nicola Salmoria Engineering
-- Jenny Murphy Producer
-- David Alonzo Assistant Producer
-- Tyler Chan Associate Producer
-- Karla Quiros Manager Business Finance & Ops
-- Special thanks to A-R&D
