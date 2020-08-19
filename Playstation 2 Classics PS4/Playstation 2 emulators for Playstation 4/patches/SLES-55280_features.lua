-- Lua 5.3
-- Title: The King of Fighters '98 Ultimate Match - SLES-55280 (Europe) v1.01
-- Author: Nicola Salmoria
-- Date: April 4, 2017


apiRequest(2.0)

local gpr = require( "ee-gpr-alias" )
local kFilterMode, kWrapMode, kBlendMultiplier, kBlendFunc = require("sprite")
local PadConnectType = require("pad-connect-type")

local eeObj		= getEEObject()
local emuObj	= getEmuObject()
local gsObj		= getGsObject()


local GRAPHIC_SETTING_ADDRESS	= 0x52f1f0
local AUTO_SAVE_ADDRESS			= 0x52f200
local PROGRE_FLG_ADDRESS		= 0x542ab0


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
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
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
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
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
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
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
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
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
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
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
	sprite0.SetBlendColor(1.0,1.0,1.0,1.0)
	sprite0.Enable()

	sprite1.BindTexture(2)
	sprite1.SetPosXY(0,0)
	sprite1.SetSizeXY(1920,1080)
	sprite1.SetPosUV(0,0)
	sprite1.SetSizeUV(1920,1080)
	sprite1.Enable()
end


local VIDEOMODE_ORIGINAL		= 0*2 + 0
local VIDEOMODE_SCANLINES		= 0*2 + 1
local VIDEOMODE_ART1			= 1*2 + 0
local VIDEOMODE_ART1_SCANLINES	= 1*2 + 1
local VIDEOMODE_ART2			= 2*2 + 0
local VIDEOMODE_ART2_SCANLINES	= 2*2 + 1
local VIDEOMODE_LOGO			= 127

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


local logoON = function(fade)
	lastVideoMode = VIDEOMODE_LOGO

	sprite0.BindTexture(3)
	sprite0.SetPosXY(0,0)
	sprite0.SetSizeXY(1920,1080)
	sprite0.SetPosUV(0,0)
	sprite0.SetSizeUV(1920,1080)
	sprite0.SetBlendColor(fade,fade,fade,fade)
	sprite0.SetBlendColorEquation(blendConstFadeEquation)
	sprite0.Enable()

	sprite1.Disable()
end




-- convert unsigned int to signed
local function asSigned(n)
	local MAXINT = 0x80000000
	return (n >= MAXINT and n - 2*MAXINT) or n
end


local LH1 =	-- update splash screen
	function()
		local splashNum = eeObj.GetGpr(gpr.s1)
		if splashNum == 3 then
			local counter = eeObj.GetGpr(gpr.s0)
			local fade = 128
			if counter < 32 then
				fade = counter * 4
			elseif counter >= 192 then
				fade = 0
			elseif counter > 160 then
				fade = (192 - counter) * 4
			end
			logoON(fade / 128.0)
		elseif splashNum == 4 then
			switchVideoMode(VIDEOMODE_ORIGINAL)
		end
	end


local FH1 =	-- initialize options
	function()
		eeObj.WriteMem8(AUTO_SAVE_ADDRESS, 1)	-- ON
	end


local elementPatches = {
	[0x960] = -1000,	-- move "+" out of view
	[0x96e] = -1000,	-- move "-" out of view
	[0x97c] = -1000,	-- move "+" out of view (scroll-in)
	[0x98a] = -1000,	-- move "-" out of view (scroll-in)
	[0x998] = -1000,	-- move "+" out of view (scroll-out)
	[0x9a6] = -1000,	-- move "-" out of view (scroll-out)
	[0x9b4] = -1000,	-- move "0" out of view
	[0x9c2] = -1000,	-- move "1" out of view
	[0x9d0] = -1000,	-- move "2" out of view
	[0x9de] = -1000,	-- move "0" out of view (scroll-in)
	[0x9ec] = -1000,	-- move "1" out of view (scroll-in)
	[0x9fa] = -1000,	-- move "2" out of view (scroll-in)
	[0xa08] = -1000,	-- move "0" out of view (scroll-out)
	[0xa16] = -1000,	-- move "1" out of view (scroll-out)
	[0xa24] = -1000,	-- move "2" out of view (scroll-out)
	[0xa38] = 0x25,		-- replace "0" with "OFF"
	[0xa32] = 0xfe,		-- adjust "OFF" x position
	[0xa46] = 0x0f,		-- replace "1" with "TYPE A"
	[0xa40] = 0xfe,		-- adjust "TYPE A" x position
	[0xa54] = 0x10,		-- replace "2" with "TYPE B"
	[0xa4e] = 0xfe,		-- adjust "TYPE B" x position
	[0xac4] = 0x1f,		-- replace "0" with "OFF" (scroll-in)
	[0xabe] = 0xffae,	-- adjust "OFF" x position (scroll-in)
	[0xad2] = 0x09,		-- replace "1" with "TYPE A" (scroll-in)
	[0xacc] = 0xffae,	-- adjust "TYPE A" x position (scroll-in)
	[0xae0] = 0x0a,		-- replace "2" with "TYPE B" (scroll-in)
	[0xada] = 0xffae,	-- adjust "TYPE B" x position (scroll-in)
	[0xb50] = 0x58,		-- replace "0" with "OFF" (scroll-out)
	[0xb4a] = 0xfe,		-- adjust "OFF" x position (scroll-out)
	[0xb5e] = 0x42,		-- replace "1" with "TYPE A" (scroll-out)
	[0xb58] = 0xfe,		-- adjust "TYPE A" x position (scroll-out)
	[0xb6c] = 0x43,		-- replace "2" with "TYPE B" (scroll-out)
	[0xb66] = 0xfe,		-- adjust "TYPE B" x position (scroll-out)

	[0xcee] = -1000,	-- move "+" out of view
	[0xcfc] = -1000,	-- move "-" out of view
	[0xd0a] = -1000,	-- move "+" out of view (scroll-in)
	[0xd18] = -1000,	-- move "-" out of view (scroll-in)
	[0xd26] = -1000,	-- move "+" out of view (scroll-out)
	[0xd34] = -1000,	-- move "-" out of view (scroll-out)
	[0xd48] = 0x23,		-- replace "0"  with "ON OFF"
	[0xd42] = 0xfd,		-- adjust "ON OFF" x position
	[0xd50] = -1000,	-- move "1" out of view
	[0xd5e] = -1000,	-- move "2" out of view
	[0xd72] = 0x1d,		-- replace "0"  with "ON OFF" (scroll-in)
	[0xd6c] = 0xffad,	-- adjust "ON OFF" x position (scroll-in)
	[0xd7a] = -1000,	-- move "1" out of view (scroll-in)
	[0xd88] = -1000,	-- move "2" out of view (scroll-in)
	[0xd9c] = 0x56,		-- replace "0"  with "ON OFF" (scroll-out)
	[0xd96] = 0xfd,		-- adjust "ON OFF" x position (scroll-out)
	[0xda4] = -1000,	-- move "1" out of view (scroll-out)
	[0xdb2] = -1000,	-- move "2" out of view (scroll-out)
	[0xdc6] = 0x25,		-- replace "0" with "OFF"
	[0xdc0] = 0x114,	-- adjust "OFF" x position
	[0xdd4] = 0x24,		-- replace "1" with "ON"
	[0xdce] = 0xe3,		-- adjust "ON" x position
	[0xe52] = 0x1f,		-- replace "0" with "OFF" (scroll-in)
	[0xe4c] = 0xffc4,	-- adjust "OFF" x position (scroll-in)
	[0xe60] = 0x1e,		-- replace "1" with "ON" (scroll-in)
	[0xe5a] = 0xff93,	-- adjust "ON" x position (scroll-in)
	[0xede] = 0x58,		-- replace "0" with "OFF" (scroll-out)
	[0xed8] = 0x114,	-- adjust "OFF" x position (scroll-out)
	[0xeec] = 0x57,		-- replace "1" with "ON" (scroll-out)
	[0xee6] = 0xe3,		-- adjust "ON" x position (scroll-out)
}

local atlasPatches = {
	-- "POSITION X" -> "ARTWORK"
	[0x18e] = 0xffda,	-- adjust X offset
	[0x192] = 0,		-- no other quads after this

	-- highlighted "POSITION X" -> "ARTWORK"
	[0x10e] = 0xffda,	-- adjust X offset
	[0x112] = 0,		-- no other quads after this

	-- "POSITION Y" -> "SCANLINES"
	[0x6a6] = 0x80,		-- adjust texture U
	[0x6a8] = 0x70,		-- adjust texture V
	[0x6aa] = 0x78,		-- adjust texture width
	[0x6ae] = 0xffc2,	-- adjust X offset
	[0x6b2] = 0,		-- no other quads after this

	-- highlighted "POSITION Y" -> "SCANLINES"
	[0x688] = 0x60,		-- adjust texture V
	[0x68a] = 0x78,		-- adjust texture width
	[0x68e] = 0xffc2,	-- adjust X offset
	[0x692] = 0,		-- no other quads after this
}

local texturePatches = {
	-- "POSITION" -> "ARTWORK"
	[0x5099] = "02222222222200222222222222002222222222202222200022222002222222222200222222222222002222200022222",
	[0x5199] = "22444444444220244444444442202444444444202444200024442022444444444220244444444442202444200024442",
	[0x5299] = "24442222244420244422222444202222444222202444200024442024442222244420244422222444202444200024442",
	[0x5399] = "24442000244420244420002444200002444200002444200024442024442000244420244420002444202444200024442",
	[0x5499] = "24442000244420244420002444200002444200002444222224442024442000244420244420002444202444200024442",
	[0x5599] = "24442000244420244420002444200002444200002444244424442024442000244420244420002444202444200024442",
	[0x5699] = "24442222244420244422222444200002444200002444244424442024442000244420244422222444202444222224442",
	[0x5799] = "24444444444420244444444422200002444200002444244424442024442000244420244444444422202444444444422",
	[0x5899] = "24442222244420244422222444200002444200002244444444422024442000244420244422222444202444222224442",
	[0x5999] = "24442000244420244420002444200002444200000244422244420024442000244420244420002444202444200024442",
	[0x5a99] = "24442000244420244420002444200002444200000244420244420024442000244420244420002444202444200024442",
	[0x5b99] = "24442000244420244420002444200002444200000244420244420024442000244420244420002444202444200024442",
	[0x5c99] = "24442000244420244420002444200002444200000244420244420024442222244420244420002444202444200024442",
	[0x5d99] = "24442000244420244420002444200002444200000244420244420022444444444220244420002444202444200024442",
	[0x5e99] = "22222000222220222220002222200002222200000222220222220002222222222200222220002222202222200022222",

	-- highlighted "POSITION" -> "ARTWORK"
	[0x1001] = "09999999999900999999999999009999999999909999900099999009999999999900999999999999009999900099999",
	[0x1101] = "99333333333990933333333339909333333333909333900093339099333333333990933333333339909333900093339",
	[0x1201] = "93339999933390933399999333909999333999909333900093339093339999933390933399999333909333900093339",
	[0x1301] = "93339000933390933390009333900009333900009333900093339093339000933390933390009333909333900093339",
	[0x1401] = "93339000933390933390009333900009333900009333999993339093339000933390933390009333909333900093339",
	[0x1501] = "93339000933390933390009333900009333900009333933393339093339000933390933390009333909333900093339",
	[0x1601] = "93339999933390933399999333900009333900009333933393339093339000933390933399999333909333999993339",
	[0x1701] = "93333333333390933333333339900009333900009333933393339093339000933390933333333339909333333333399",
	[0x1801] = "93339999933390933399999333900009333900009933333333399093339000933390933399999333909333999993339",
	[0x1901] = "93339000933390933390009333900009333900000933399933390093339000933390933390009333909333900093339",
	[0x1a01] = "93339000933390933390009333900009333900000933390933390093339000933390933390009333909333900093339",
	[0x1b01] = "93339000933390933390009333900009333900000933390933390093339000933390933390009333909333900093339",
	[0x1c01] = "93339000933390933390009333900009333900000933390933390093339999933390933390009333909333900093339",
	[0x1d01] = "93339000933390933390009333900009333900000933390933390099333333333990933390009333909333900093339",
	[0x1e01] = "99999000999990999990009999900009999900000999990999990009999999999900999990009999909999900099999",

	-- "DEMO CUT" (unused) -> "SCANLINES"
	[0x7083] = "022222222222000222222222220002222222222200222222002222202222200000000022222022222200222220022222222222200222222222220",
	[0x7183] = "224444444442202244444444422022444444444220244442202444202444200000000024442024444220244420224444444444202244444444422",
	[0x7283] = "244422222444202444222224442024442222244420244449202444202444200000000024442024444920244420244422222222202444222224442",
	[0x7383] = "244420002444202444200024442024442000244420244444222444202444200000000024442024444422244420244420000000002444200024442",
	[0x7483] = "244420002222202444200022222024442000244420244444922444202444200000000024442024444492244420244420000000002444200022222",
	[0x7583] = "244420000000002444200000000024442000244420244444422444202444200000000024442024444442244420244420000000002444200000000",
	[0x7683] = "244422222222002444200000000024442222244420244494492444202444200000000024442024449449244420244422222220002444222222220",
	[0x7783] = "224444444442202444200000000024444444444420244424442444202444200000000024442024442444244420244444444420002244444444422",
	[0x7883] = "022222222444202444200000000024442222244420244429449444202444200000000024442024442944944420244422222220000222222224442",
	[0x7983] = "000000002444202444200000000024442000244420244422444444202444200022222024442024442244444420244420000000000000000024442",
	[0x7a83] = "222220002444202444200022222024442000244420244422944444202444200024442024442024442294444420244420000000002222200024442",
	[0x7b83] = "244420002444202444200024442024442000244420244422244444202444200024442024442024442224444420244420000000002444200024442",
	[0x7c83] = "244422222444202444222224442024442000244420244420294444202444222224442024442024442029444420244422222222202444222224442",
	[0x7d83] = "224444444442202244444444422024442000244420244420224444202444444444442024442024442022444420224444444444202244444444422",
	[0x7e83] = "022222222222000222222222220022222000222220222220022222202222222222222022222022222002222220022222222222200222222222220",

	-- highlighted "DEMO CUT" (unused) -> "SCANLINES"
	[0x6002] = "0099999999999000999999999990009999999999900999999009999909999900000000099999099999900999990099999999999900999999999990",
	[0x6102] = "0993333333339909933333333399099333333333990933339909333909333900000000093339093333990933390993333333333909933333333399",
	[0x6202] = "0933399999333909333999993339093339999933390933332909333909333900000000093339093333290933390933399999999909333999993339",
	[0x6302] = "0933390009333909333900093339093339000933390933333999333909333900000000093339093333399933390933390000000009333900093339",
	[0x6402] = "0933390009999909333900099999093339000933390933333299333909333900000000093339093333329933390933390000000009333900099999",
	[0x6502] = "0933390000000009333900000000093339000933390933333399333909333900000000093339093333339933390933390000000009333900000000",
	[0x6602] = "0933399999999009333900000000093339999933390933323329333909333900000000093339093332332933390933399999990009333999999990",
	[0x6702] = "0993333333339909333900000000093333333333390933393339333909333900000000093339093339333933390933333333390009933333333399",
	[0x6802] = "0099999999333909333900000000093339999933390933392332333909333900000000093339093339233233390933399999990000999999993339",
	[0x6902] = "0000000009333909333900000000093339000933390933399333333909333900099999093339093339933333390933390000000000000000093339",
	[0x6a02] = "0999990009333909333900099999093339000933390933399233333909333900093339093339093339923333390933390000000009999900093339",
	[0x6b02] = "0933390009333909333900093339093339000933390933399933333909333900093339093339093339993333390933390000000009333900093339",
	[0x6c02] = "0933399999333909333999993339093339000933390933390923333909333999993339093339093339092333390933399999999909333999993339",
	[0x6d02] = "0993333333339909933333333399093339000933390933390993333909333333333339093339093339099333390993333333333909933333333399",
	[0x6e02] = "0099999999999000999999999990099999000999990999990099999909999999999999099999099999009999990099999999999900999999999990",
}

local FH2A =	-- initialize display options screen layout
	function()
		local layout = eeObj.GetGpr(gpr.a1)
		local elements = layout + eeObj.ReadMem32(layout + 12)

		for offset, value in pairs(elementPatches) do
			eeObj.WriteMem16(elements + offset, value)
		end

		local atlas = layout + eeObj.ReadMem32(layout + 4)
		for offset, value in pairs(atlasPatches) do
			eeObj.WriteMem16(atlas + offset, value)
		end

		local bitmap = layout + eeObj.ReadMem32(layout) + 0x440
		for offset, str in pairs(texturePatches) do
			local l = string.len(str)
			for i = 1, l do
				local c = string.sub(str, i, i)
				eeObj.WriteMem8(bitmap + offset + i - 1, string.byte(c) - 0x30)
			end
		end
	end


local FH2B =	-- adjust Position X (now Artwork) setting
	function()
		local posX = asSigned(eeObj.GetGpr(gpr.a0))
		eeObj.SetGpr(gpr.a0, posX % 3)	-- limit to valid range
	end


local FH2C =	-- adjust Position Y (now Scanlines) setting
	function()
		local posX = asSigned(eeObj.GetGpr(gpr.a0))
		eeObj.SetGpr(gpr.a0, posX % 2)	-- limit to valid range
	end


local finishedSplashScreens = false

local settingPosX = 0
local FH3A =	-- apply display position x/y settings (now Artwork/Scanlines)
	function()
		settingPosX = eeObj.GetGpr(gpr.a1)
		eeObj.SetGpr(gpr.a1, 0)	-- force pos X to 0
	end
		
local FH3B =
	function()
		local settingPosY = eeObj.GetGpr(gpr.v1)
		eeObj.SetGpr(gpr.v1, 0)	-- force pos Y to 0

		-- limit to valid range
		settingPosX = settingPosX % 3
		settingPosY = settingPosY % 2

		if finishedSplashScreens == true then
			switchVideoMode(settingPosX * 2 + settingPosY)
		end
	end

local FH3C =
	function()
		eeObj.SetGpr(gpr.a2, 0)	-- force pos Y to 0
	end

local FH3D =	-- finish splash screens
	function()
		finishedSplashScreens = true
	end


local FH4A =	-- init display
	function()
		-- force progressive mode
		eeObj.SetGpr(gpr.a1, 0)
		eeObj.SetGpr(gpr.a2, 80)
		eeObj.SetGpr(gpr.a3, 1)
		
		eeObj.WriteMem8(PROGRE_FLG_ADDRESS, 1)	-- ON
	end


local FH4B =	-- check X + Triangle on boot
	function()
		eeObj.SetGpr(gpr.v0, 0)	-- always ignore
	end



-- register hooks

local hooks = {
	-- SNK logo
	eeObj.AddHook(0x464f18, 0x0000202d, LH1),	-- <logo_task>:

	-- turn on auto save
	eeObj.AddHook(0x329b34, 0x0000282d, FH1),	-- <init_option>:

	-- patch Position x/y options to show Artwork/Scanlines options
	eeObj.AddHook(0x4453a4, 0x0200282d, FH2A),	-- <UM_GRAPHIC_SETTING>:
	eeObj.AddHook(0x445558, 0x24a40001, FH2B),	-- <UM_GRAPHIC_SETTING_2000>:
	eeObj.AddHook(0x4457c0, 0x24a4ffff, FH2B),	-- <UM_GRAPHIC_SETTING_2000>:
	eeObj.AddHook(0x445594, 0x24a40001, FH2C),	-- <UM_GRAPHIC_SETTING_2000>:
	eeObj.AddHook(0x4457fc, 0x24a4ffff, FH2C),	-- <UM_GRAPHIC_SETTING_2000>:

	-- apply artwork / scanlines settings
	eeObj.AddHook(0x329bcc, 0x8065f1f3, FH3A),	-- <DisplayPositionSet>:
	eeObj.AddHook(0x329bec, 0x8063f1f4, FH3B),	-- <DisplayPositionSet>:
	eeObj.AddHook(0x329c18, 0x8046f1f4, FH3C),	-- <DisplayPositionSet>:
	eeObj.AddHook(0x464fa8, 0x7bb00000, FH3D),	-- <logo_task>:

	-- force Progressive mode
	eeObj.AddHook(0x100290, 0x27bdffb0, FH4A),	-- <sceGsResetGraph>:
	eeObj.AddHook(0x1b5e98, 0x90422a98, FH4B),	-- <DEMO_INIT_200>:
}

-- force 60Hz mode
eeInsnReplace(0x47a9c0, 0x0c11e9e4, 0x24020002)	-- li	$v0,2
eeInsnReplace(0x47a9b8, 0x0c11e934, 0x00000000)	-- nop
eeInsnReplace(0x47a9e8, 0x0c11e950, 0x00000000)	-- nop
eeInsnReplace(0x3290e0, 0x5440000c, 0x00000000)	-- nop


-- Fight stick

HIDPad_Enable()

local addedHooks = false
local pad = function()
	if addedHooks == false then
		addedHooks = true
		switchVideoMode(VIDEOMODE_ORIGINAL)
		emuObj.AddVsyncHook(update_notifications_p1)
		emuObj.AddVsyncHook(update_notifications_p2)

-- test message on boot
--		onHIDPadEvent(0, true, PadConnectType.HID)

		-- disable interpolation
		gsObj.SetUprenderMode("none")
		gsObj.SetUpscaleMode("point")

		-- bug report:
		-- The sound volume is too loud and could you please decrease to -24LKF (�2) as PS4 recommended?
		-- The current sound volume: -10.21LKFS
		--
		-- So set main volume to 10^(-14/20) ~= 0.2 i.e. about 14dB attenuation.
		emuObj.SetVolumes(0.2, 1.0, 1.0)
	end
end

emuObj.AddPadHook(onHIDPadEvent)
emuObj.AddEntryPointHook(pad)


--=======================================  WBD addition 11/29/2017

-- Fix bug 10414 - large stretched polygons block view of player characters

local FixPointTable = function()
--		local pPtTbl = eeObj.ReadMem32(p5Tbl+0x114)		-- ptr to source points DEBUG ONLY
		
		local s6 = eeObj.GetGpr(gpr.s6)					-- obj in question 
		local p5Tbl = eeObj.ReadMem32(s6+0x10)			-- ptr to object's data
		local numPts = eeObj.ReadMem32(p5Tbl+0x110)		-- num points in list
		local pTbl = 0x1bd6ce0							-- bg_point_buff (we need to scan this)
		for i = 1, numPts do
			local stat = eeObj.ReadMem32(pTbl + 0xc)	-- check 4th word, should be 0
			if (stat ~= 0) then							-- if not, we need to fix

--[[			DEBUG ONLY, print source point
				local w1 = eeObj.ReadMemFloat(pPtTbl)
				local w2 = eeObj.ReadMemFloat(pPtTbl+4)
				local w3 = eeObj.ReadMemFloat(pPtTbl+8)
				local w4 = eeObj.ReadMemFloat(pPtTbl+12)
				print (string.format("_NOTE: Point %d, %x (%f, %f, %f, %f) needs fixing", i, pPtTbl, w1,w2,w3,w4))
--]]				
				if (i > 1) then							-- if this is any but the first entry
					stat = eeObj.ReadMem64(pTbl-0x10)	-- fix by replacing the x, y with
					eeObj.WriteMem64(pTbl, stat)		-- the previous entry's x and y.
--					stat = eeObj.ReadMem64(pTbl-8)
					stat = 0x0000000080000000			-- replace the z with 0x80000000
					eeObj.WriteMem64(pTbl+8, stat)		-- replace the 4th word with 0
--					print "_NOTE: Fixed with previous entry"
				else
					stat = eeObj.ReadMem32(pTbl + 0x1c)	-- if this is the first entry
					if (stat == 0) then					-- make sure the second entry is kosher
						stat = eeObj.ReadMem64(pTbl+0x10)
						eeObj.WriteMem64(pTbl, stat)	-- if it is, use the x, y from that entry.
--						stat = eeObj.ReadMem64(pTbl+0x18)
						stat = 0x0000000080000000		-- replace the z with 0x80000000
						eeObj.WriteMem64(pTbl+8, stat)	-- replace the 4th word with 0			
--						print "_NOTE: Fixed with next entry"
					else
						eeObj.WriteMem64(pTbl, 0)						-- if the 2nd entry is not kosher
						eeObj.WriteMem64(pTbl+8, 0x0000000080000000)	-- write 0, 0, 0x80000000, 0
--						print "_NOTE: Fixed with (0, 0, 0x80000000, 0)"
					end
				end
			else										-- check if Z value is between 0 and 0x8000
				stat = eeObj.ReadMem32(pTbl + 8)		-- if so, overwrite Z with 0x80000000
				if (stat <= 0x8000) then
					eeObj.WriteMem32(pTbl+8, 0x80000000)
--					print (string.format("_NOTE: Fixed positive Z = %x", stat))
				end
			end
			pTbl = pTbl + 0x10 
--			pPtTbl = pPtTbl + 0x10				-- DEBUG ONLY
		end	
end

eeObj.AddHook(0x439dc8, 0x008e150180, FixPointTable)

eeInsnReplace(0x3298ac, 0xa064f1f2, 0xa060f1f2)   -- Change default Focus setting from Soft to Normal
