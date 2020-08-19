-- Lua 5.3
-- Title:   Manhunt PS2 - SLUS-20827 (USA)
-- Author:  Ernesto Corvi

-- Changelog:
-- v1.4: Added Widescreen support

require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])
require( "ee-cpr0-alias" ) -- for EE CPR

apiRequest(0.7)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()

local L1 =  -- CFrontend::LoadProgressDraw
	function()
		local total = eeObj.GetGpr(gpr.a0) - 1
		local cur = eeObj.GetGpr(gpr.a1)
		
		if total > 0 then
			if cur == 1 then
				emuObj.ThrottleMax()
			elseif cur >= total then
				emuObj.ThrottleNorm()
			end
		end
	end
	
local L2 =  -- main
	function()
		emuObj.ThrottleMax()
	end
	
local L3 =  -- main
	function()
		emuObj.ThrottleNorm()
	end

local load1 = eeObj.AddHook(0x1100d0, 0x27bdff80, L1) -- CFrontend::LoadProgressDraw
local load2 = eeObj.AddHook(0x25154c, 0x8f84b4ec, L2) -- main
local load3 = eeObj.AddHook(0x2515b8, 0x8f82b4ec, L3) -- main

-- Widescreen support

local W1 = -- CScene::SetViewWindowDefault
	function()
		emuObj.SetDisplayAspectNormal()
	end
	
local W2 = -- CScene::SetViewWindowWidescreen
	function()
		emuObj.SetDisplayAspectWide()
	end

local ws1 = eeObj.AddHook(0x1c9840, 0xaf808c78, W1) -- CScene::SetViewWindowDefault
local ws2 = eeObj.AddHook(0x1c985c, 0xaf848c78, W2) -- CScene::SetViewWindowWidescreen

-- CMhGlobalData::SetDefaults (default to widescreen)
eeInsnReplace(0x3a7758, 0xae000034, 0xae060034) -- sw $zero, 0x34($s0) -> sw $a2, 0x34($s0)
emuObj.SetDisplayAspectWide()
